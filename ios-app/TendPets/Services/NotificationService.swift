import Foundation
import UserNotifications

enum ReminderNotificationAction {
    case done(planId: UUID)
    case snooze(planId: UUID, minutes: Int)
    case opened(planId: UUID)
}

@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private var actionHandler: ((ReminderNotificationAction) -> Void)?
    private var pendingActions: [ReminderNotificationAction] = []

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            true
        default:
            false
        }
    }

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    func configureActionHandler(_ handler: @escaping (ReminderNotificationAction) -> Void) {
        actionHandler = handler
        pendingActions.forEach(handler)
        pendingActions.removeAll()
    }

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            refreshAuthorizationStatus()
            registerCategories()
            return granted
        } catch {
            return false
        }
    }

    func schedule(plan: CarePlan, pet: Pet) async {
        guard plan.notificationEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(pet.name)'s \(plan.name) is due"
        content.body = plan.detail
        content.sound = .default
        content.categoryIdentifier = "CARE_REMINDER"
        content.userInfo = [
            "planId": plan.id.uuidString,
            "petId": pet.id.uuidString
        ]

        let trigger: UNNotificationTrigger
        switch plan.repeatRule {
        case .daily:
            var components = DateComponents()
            components.hour = plan.timeHour
            components.minute = plan.timeMinute
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .onDate:
            guard let specificDate = plan.specificDate else {
                // Without a date we cannot schedule a one-shot reminder.
                return
            }
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: specificDate)
            components.hour = plan.timeHour
            components.minute = plan.timeMinute
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        let request = UNNotificationRequest(identifier: plan.id.uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func scheduleSnooze(plan: CarePlan, pet: Pet, minutes: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "\(pet.name)'s \(plan.name) is due"
        content.body = "Snoozed reminder"
        content.sound = .default
        content.categoryIdentifier = "CARE_REMINDER"
        content.userInfo = [
            "planId": plan.id.uuidString,
            "petId": pet.id.uuidString
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(plan.id.uuidString).snooze",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func scheduleTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Tend Pets reminder test"
        content.body = "Notifications are ready for care reminders."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "tendpets.test", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    // nonisolated so the nonisolated UNUserNotificationCenterDelegate callback
    // (didReceive response) can reference it without crossing actor isolation.
    nonisolated static let snoozeDefaultMinutes = 30

    /// Cancel any pending reminders (main + snooze) for a specific plan. Call this
    /// when the user deletes a care plan so the OS does not fire notifications for
    /// a plan that no longer exists.
    func cancelReminders(for planId: UUID) {
        let center = UNUserNotificationCenter.current()
        let identifiers = [planId.uuidString, "\(planId.uuidString).snooze"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Cancel every Tend Pets reminder. Call this when the user wipes all data.
    func cancelAllReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func registerCategories() {
        let done = UNNotificationAction(identifier: "CARE_DONE", title: "Done", options: [])
        let snooze = UNNotificationAction(
            identifier: "CARE_SNOOZE",
            title: "Snooze \(Self.snoozeDefaultMinutes) min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "CARE_REMINDER",
            actions: [done, snooze],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard
            let planIdText = response.notification.request.content.userInfo["planId"] as? String,
            let planId = UUID(uuidString: planIdText)
        else {
            completionHandler()
            return
        }

        let action: ReminderNotificationAction
        switch response.actionIdentifier {
        case "CARE_DONE":
            action = .done(planId: planId)
        case "CARE_SNOOZE":
            action = .snooze(planId: planId, minutes: NotificationService.snoozeDefaultMinutes)
        default:
            action = .opened(planId: planId)
        }

        Task { @MainActor [weak self] in
            self?.dispatch(action)
            completionHandler()
        }
    }

    private func dispatch(_ action: ReminderNotificationAction) {
        if let actionHandler {
            actionHandler(action)
        } else {
            pendingActions.append(action)
        }
    }
}
