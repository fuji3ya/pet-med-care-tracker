You are reviewing a SwiftUI iPhone app for App Store readiness. Focus only on concrete blockers or high-risk issues in this code. Do not give generic SwiftUI advice. Output in Japanese with: Critical / High / Medium / No issue.

Context: The app is Tend Pets, a pet medication and care reminder app. Recent fixes added local notification Done/Snooze handling, Add Care validation, and test notifications.
## REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Services\NotificationService.swift
```swift
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

        var date = DateComponents()
        date.hour = plan.timeHour
        date.minute = plan.timeMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: plan.repeatRule == .daily)
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

    func registerCategories() {
        let done = UNNotificationAction(identifier: "CARE_DONE", title: "Done")
        let snooze = UNNotificationAction(identifier: "CARE_SNOOZE", title: "Snooze")
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
            action = .snooze(planId: planId, minutes: 10)
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

```

## REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\App\AppState.swift
```swift
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var pets: [Pet]
    @Published var carePlans: [CarePlan]
    @Published var occurrences: [CareOccurrence]
    @Published var records: [CareRecord]

    private let storage = LocalStorage()

    init() {
        let snapshot = storage.load()
        pets = snapshot.pets
        carePlans = snapshot.carePlans
        occurrences = snapshot.occurrences
        records = snapshot.records

        if pets.isEmpty {
            let sample = Pet(name: "Momo", species: .cat, birthYear: 2014, weightValue: 4.2, weightUnit: .kg)
            pets = [sample]
            let plan = CarePlan(
                petId: sample.id,
                type: .medicine,
                name: "Heart med",
                detail: "1 tablet, after breakfast",
                timeHour: 8,
                timeMinute: 0,
                repeatRule: .daily
            )
            carePlans = [plan]
            occurrences = [
                CareOccurrence(planId: plan.id, petId: sample.id, dueAt: Date(), status: .due)
            ]
        }
    }

    var todaysOccurrences: [CareOccurrence] {
        occurrences.sorted { $0.dueAt < $1.dueAt }
    }

    func pet(for id: UUID) -> Pet? {
        pets.first { $0.id == id }
    }

    func plan(for id: UUID) -> CarePlan? {
        carePlans.first { $0.id == id }
    }

    func markDone(_ occurrence: CareOccurrence) {
        updateOccurrence(occurrence.id) { item in
            item.status = .done
            item.completedAt = Date()
            item.completedBy = "Alex"
        }
        save()
    }

    func markDone(planId: UUID) {
        guard let index = activeOccurrenceIndex(forPlanId: planId) else { return }
        occurrences[index].status = .done
        occurrences[index].completedAt = Date()
        occurrences[index].completedBy = "Notification"
        save()
    }

    func snooze(_ occurrence: CareOccurrence, minutes: Int) {
        updateOccurrence(occurrence.id) { item in
            item.status = .upcoming
            item.dueAt = Calendar.current.date(byAdding: .minute, value: minutes, to: Date()) ?? Date()
            item.note = "Snoozed \(minutes) minutes"
        }
        save()
    }

    func snooze(planId: UUID, minutes: Int) {
        guard let index = activeOccurrenceIndex(forPlanId: planId) else { return }
        occurrences[index].status = .upcoming
        occurrences[index].dueAt = Calendar.current.date(byAdding: .minute, value: minutes, to: Date()) ?? Date()
        occurrences[index].note = "Snoozed \(minutes) minutes from notification"
        save()
    }

    func skip(_ occurrence: CareOccurrence, reason: String) {
        updateOccurrence(occurrence.id) { item in
            item.status = .skipped
            item.skipReason = reason
            item.completedAt = Date()
            item.completedBy = "Alex"
        }
        save()
    }

    func addCarePlan(_ plan: CarePlan) {
        carePlans.append(plan)
        occurrences.append(
            CareOccurrence(planId: plan.id, petId: plan.petId, dueAt: plan.nextDueDate(), status: .due)
        )
        save()
    }

    func save() {
        storage.save(AppSnapshot(pets: pets, carePlans: carePlans, occurrences: occurrences, records: records))
    }

    private func updateOccurrence(_ id: UUID, mutate: (inout CareOccurrence) -> Void) {
        guard let index = occurrences.firstIndex(where: { $0.id == id }) else { return }
        mutate(&occurrences[index])
    }

    private func activeOccurrenceIndex(forPlanId planId: UUID) -> Int? {
        occurrences
            .enumerated()
            .filter { $0.element.planId == planId && $0.element.status != .done && $0.element.status != .skipped }
            .min { $0.element.dueAt < $1.element.dueAt }?
            .offset
    }
}

```

## REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\App\TendPetsApp.swift
```swift
import SwiftUI

@main
struct TendPetsApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store = SubscriptionStore()
    @StateObject private var notifications = NotificationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(store)
                .environmentObject(notifications)
                .task {
                    await store.start()
                    notifications.refreshAuthorizationStatus()
                    notifications.configureActionHandler { action in
                        switch action {
                        case .done(let planId):
                            appState.markDone(planId: planId)
                        case .snooze(let planId, let minutes):
                            appState.snooze(planId: planId, minutes: minutes)
                            if let plan = appState.plan(for: planId),
                               let pet = appState.pet(for: plan.petId) {
                                Task {
                                    await notifications.scheduleSnooze(plan: plan, pet: pet, minutes: minutes)
                                }
                            }
                        case .opened:
                            break
                        }
                    }
                }
        }
    }
}

```

## REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\TodayView.swift
```swift
import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @State private var snoozeOccurrence: CareOccurrence?
    @State private var skipOccurrence: CareOccurrence?
    @State private var showSkipSheet = false

    var body: some View {
        List {
            if let pet = appState.pets.first {
                Section {
                    HStack(spacing: 12) {
                        CareRingView(progress: 0.67, initial: String(pet.name.prefix(1)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(pet.name)
                                .font(.headline)
                            Text("Tue, May 5 - 4 of 6 done")
                                .font(.subheadline)
                                .foregroundStyle(TPColor.muted)
                        }
                        Spacer()
                        Text("67%")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(TPColor.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(TPColor.primarySoft, in: Capsule())
                    }
                }
            }

            Section("Due now") {
                ForEach(appState.todaysOccurrences) { occurrence in
                    if let plan = appState.plan(for: occurrence.planId),
                       let pet = appState.pet(for: occurrence.petId) {
                        CareCardView(
                            pet: pet,
                            plan: plan,
                            occurrence: occurrence,
                            onDone: { appState.markDone(occurrence) },
                            onSnooze: { snoozeOccurrence = occurrence },
                            onSkip: {
                                skipOccurrence = occurrence
                                showSkipSheet = true
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                }
            }

            Section("Later today") {
                Label("Breakfast notes", systemImage: "fork.knife")
                Label("Rio eye drops - 12:30", systemImage: "drop")
                Label("Luna vet visit - 16:00", systemImage: "cross.case")
            }
        }
        .navigationTitle("Today")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .sheet(item: $snoozeOccurrence) { occurrence in
            SnoozeSheet(occurrence: occurrence)
                .environmentObject(appState)
                .presentationDetents([.height(240)])
        }
        .confirmationDialog("Skip with note", isPresented: $showSkipSheet, titleVisibility: .visible) {
            Button("Not eating") {
                if let skipOccurrence {
                    appState.skip(skipOccurrence, reason: "Not eating")
                }
            }
            Button("Vet instructed") {
                if let skipOccurrence {
                    appState.skip(skipOccurrence, reason: "Vet instructed")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct CareCardView: View {
    var pet: Pet
    var plan: CarePlan
    var occurrence: CareOccurrence
    var onDone: () -> Void
    var onSnooze: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(statusText)
                .font(.caption.weight(.bold))
                .foregroundStyle(statusColor)
            Text("\(pet.name)'s \(plan.name)")
                .font(.title3.weight(.bold))
            Text(plan.detail)
                .font(.subheadline)
                .foregroundStyle(TPColor.muted)

            if occurrence.status == .done || occurrence.status == .skipped {
                Text(completionText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TPColor.primary)
            } else {
                HStack(spacing: 8) {
                    Button("Done", action: onDone)
                        .buttonStyle(PrimaryPillButtonStyle())
                    Button("Snooze", action: onSnooze)
                        .buttonStyle(NeutralPillButtonStyle())
                    Button("Skip", action: onSkip)
                        .buttonStyle(NeutralPillButtonStyle())
                }
            }
        }
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var statusText: String {
        switch occurrence.status {
        case .done: "Done"
        case .skipped: "Skipped"
        case .missed: "Missed"
        default: "Due now"
        }
    }

    private var statusColor: Color {
        occurrence.status == .missed ? TPColor.alert : TPColor.primary
    }

    private var completionText: String {
        switch occurrence.status {
        case .done:
            "Completed by \(occurrence.completedBy ?? "Caregiver")"
        case .skipped:
            "Skipped: \(occurrence.skipReason ?? "No reason")"
        default:
            ""
        }
    }

    private var cardBackground: LinearGradient {
        LinearGradient(colors: [TPColor.primarySoft, .white], startPoint: .top, endPoint: .bottom)
    }
}

struct SnoozeSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService
    var occurrence: CareOccurrence
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Snooze reminder")
                .font(.title2.weight(.bold))
            Text("We will remind you again when you have a moment.")
                .foregroundStyle(TPColor.muted)
            HStack {
                Button("10 min") {
                    snooze(minutes: 10)
                }
                    .buttonStyle(PrimaryPillButtonStyle())
                Button("30 min") {
                    snooze(minutes: 30)
                }
                    .buttonStyle(NeutralPillButtonStyle())
                Button("1 hour") {
                    snooze(minutes: 60)
                }
                    .buttonStyle(NeutralPillButtonStyle())
            }
            Spacer()
        }
        .padding()
    }

    private func snooze(minutes: Int) {
        appState.snooze(occurrence, minutes: minutes)
        if let plan = appState.plan(for: occurrence.planId),
           let pet = appState.pet(for: occurrence.petId) {
            Task {
                await notifications.scheduleSnooze(plan: plan, pet: pet, minutes: minutes)
            }
        }
        dismiss()
    }
}

struct PrimaryPillButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(TPColor.primary.opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.35), in: Capsule())
            .foregroundStyle(.white)
    }
}

struct NeutralPillButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6).opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45), in: Capsule())
            .foregroundStyle(isEnabled ? TPColor.text : TPColor.muted)
    }
}

```

## REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\AddCareView.swift
```swift
import SwiftUI

struct AddCareView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService

    @State private var type: CareType = .medicine
    @State private var name = "Heart med"
    @State private var detail = "1 tablet, after breakfast"
    @State private var dueTime = Date()
    @State private var repeatRule: RepeatRule = .daily
    @State private var selectedPetId: UUID?
    @State private var validationMessage: String?

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $type) {
                    ForEach(CareType.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Reminder") {
                Picker("Pet", selection: $selectedPetId) {
                    ForEach(appState.pets) { pet in
                        Text(pet.name).tag(Optional(pet.id))
                    }
                }
                TextField("Name", text: $name)
                TextField("Details", text: $detail)
                DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                Picker("Repeat", selection: $repeatRule) {
                    ForEach(RepeatRule.allCases) { rule in
                        Text(rule.rawValue).tag(rule)
                    }
                }
            }

            Section("Notifications") {
                HStack {
                    Text("Notify at care time")
                    Spacer()
                    Text(notifications.authorizationStatus == .authorized ? "On" : "Not enabled")
                        .foregroundStyle(TPColor.muted)
                }
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(TPColor.alert)
                }
            }

            Button("Save reminder") {
                save()
            }
            .disabled(!canSave)
            .buttonStyle(PrimaryPillButtonStyle())
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Add Care")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .onAppear {
            selectedPetId = selectedPetId ?? appState.pets.first?.id
        }
    }

    private var canSave: Bool {
        selectedPetId != nil && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Reminder name is required."
            return
        }

        guard
            let selectedPetId,
            let pet = appState.pet(for: selectedPetId)
        else {
            validationMessage = "Choose a pet before saving."
            return
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: dueTime)
        let plan = CarePlan(
            petId: pet.id,
            type: type,
            name: trimmedName,
            detail: trimmedDetail.isEmpty ? "Care reminder" : trimmedDetail,
            timeHour: components.hour ?? 8,
            timeMinute: components.minute ?? 0,
            repeatRule: repeatRule
        )
        appState.addCarePlan(plan)
        validationMessage = nil
        Task {
            if notifications.authorizationStatus == .notDetermined {
                _ = await notifications.requestAuthorization()
            }
            await notifications.schedule(plan: plan, pet: pet)
        }
    }
}

```

## REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\SettingsView.swift
```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var store: SubscriptionStore
    @State private var showPaywall = false

    var body: some View {
        List {
            Section("Reminders") {
                HStack {
                    Label("Notifications", systemImage: "bell")
                    Spacer()
                    Text(notificationText)
                        .foregroundStyle(TPColor.muted)
                }
                Button("Enable notifications") {
                    Task { _ = await notifications.requestAuthorization() }
                }
                Button("Test notification") {
                    Task {
                        if notifications.authorizationStatus == .notDetermined {
                            _ = await notifications.requestAuthorization()
                        }
                        await notifications.scheduleTestNotification()
                    }
                }
            }

            Section("Subscription") {
                Button(store.hasPlus ? "Manage Tend Pets Plus" : "Upgrade to Plus") {
                    showPaywall = true
                }
                Button("Restore Purchase") {
                    Task { await store.refreshEntitlements() }
                }
            }

            Section("Data & Privacy") {
                Button("Export data") {}
                Button("Delete account", role: .destructive) {}
                NavigationLink("Medical disclaimer") {
                    Text("Tend Pets helps you record and remember care routines. It does not provide veterinary medical advice. Always follow your veterinarian's instructions.")
                        .padding()
                        .navigationTitle("Disclaimer")
                }
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
    }

    private var notificationText: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: "On"
        case .denied: "Off"
        case .notDetermined: "Not set"
        @unknown default: "Unknown"
        }
    }
}

struct PaywallView: View {
    @EnvironmentObject private var store: SubscriptionStore

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Keep every routine organized")
                    .font(.largeTitle.weight(.bold))
                Text("For pets with daily care, shared routines, and vet-ready records.")
                    .foregroundStyle(TPColor.muted)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Unlimited reminders", systemImage: "bell")
                    Label("Vet summary export", systemImage: "doc.text")
                    Label("Cloud backup", systemImage: "icloud")
                    Label("Up to 5 pets", systemImage: "pawprint")
                }
                .font(.headline)

                if store.products.isEmpty {
                    Text("Subscriptions are loading.")
                        .foregroundStyle(TPColor.muted)
                } else {
                    ForEach(store.products, id: \.id) { product in
                        Button {
                            Task { await store.purchase(product) }
                        } label: {
                            HStack {
                                Text(product.displayName)
                                Spacer()
                                Text(product.displayPrice)
                            }
                        }
                        .buttonStyle(NeutralPillButtonStyle())
                    }
                }

                Button("Restore Purchase") {
                    Task { await store.refreshEntitlements() }
                }
                .buttonStyle(NeutralPillButtonStyle())

                Text("Trial duration, renewal price, Terms, Privacy, and Restore Purchase must remain visible in the final StoreKit paywall.")
                    .font(.footnote)
                    .foregroundStyle(TPColor.muted)

                Spacer()
            }
            .padding()
            .navigationTitle("Tend Pets Plus")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

```
