import Foundation
import UserNotifications

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
            seedDemoData()
        }
    }

    /// First-launch sample data so the app never opens empty. Two pets (a cat and
    /// a dog) with photos, a few realistic reminders, and some history make every
    /// screen — Today, Pets, Records, and the vet summary — feel real. Users can
    /// delete this from the Pets tab or wipe it in Settings.
    private func seedDemoData() {
        let cat = Pet(name: "Momo", species: .cat, birthYear: 2014,
                      weightValue: 4.2, weightUnit: .kg, photoName: "demo-cat")
        let dog = Pet(name: "Rocky", species: .dog, birthYear: 2019,
                      weightValue: 12.5, weightUnit: .kg, photoName: "demo-dog")
        pets = [cat, dog]

        let catMed = CarePlan(petId: cat.id, type: .medicine, name: "Heart med",
                              detail: "1 tablet, after breakfast",
                              timeHour: 8, timeMinute: 0, repeatRule: .daily)
        let dogJoint = CarePlan(petId: dog.id, type: .medicine, name: "Joint supplement",
                                detail: "1 chew with dinner",
                                timeHour: 19, timeMinute: 0, repeatRule: .daily)
        let dogMeal = CarePlan(petId: dog.id, type: .food, name: "Evening meal",
                               detail: "1 cup dry food",
                               timeHour: 18, timeMinute: 30, repeatRule: .daily)
        carePlans = [catMed, dogJoint, dogMeal]

        let cal = Calendar.current
        let now = Date()
        let eightToday = cal.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        let laterToday = cal.date(byAdding: .hour, value: 3, to: now) ?? now
        occurrences = [
            CareOccurrence(planId: catMed.id, petId: cat.id, dueAt: eightToday, status: .due),
            CareOccurrence(planId: dogMeal.id, petId: dog.id, dueAt: laterToday, status: .upcoming),
            CareOccurrence(planId: dogJoint.id, petId: dog.id, dueAt: cal.date(bySettingHour: 19, minute: 0, second: 0, of: now) ?? now, status: .upcoming),
        ]

        func daysAgo(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now) ?? now }
        records = [
            CareRecord(petId: cat.id, type: .medicine, date: daysAgo(1),
                       title: "Heart med done", value: "1 tablet", note: "Completed by Caregiver"),
            CareRecord(petId: dog.id, type: .weight, date: daysAgo(3),
                       title: "Weight check", value: "12.5 kg", note: "Steady since last month"),
            CareRecord(petId: cat.id, type: .weight, date: daysAgo(12),
                       title: "Weight check", value: "4.1 kg", note: "Slight loss — mention to vet"),
            CareRecord(petId: dog.id, type: .vaccine, date: daysAgo(40),
                       title: "Rabies vaccine", value: "Lot 22-118", note: "Annual booster"),
        ]
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

    // MARK: - Free tier limits

    static let freeMaxPets = 1
    static let freeMaxActiveCarePlans = 3
    static let freeRecordsHistoryDays = 7

    func canAddPet(hasPlus: Bool) -> Bool {
        hasPlus || pets.count < Self.freeMaxPets
    }

    func canAddCarePlan(hasPlus: Bool) -> Bool {
        hasPlus || activeCarePlanCount < Self.freeMaxActiveCarePlans
    }

    var activeCarePlanCount: Int {
        carePlans.filter { $0.active }.count
    }

    func recordsVisibleToUser(hasPlus: Bool) -> [CareRecord] {
        if hasPlus { return records }
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.freeRecordsHistoryDays, to: Date()) ?? Date.distantPast
        return records.filter { $0.date >= cutoff }
    }

    func addPet(_ pet: Pet) {
        pets.append(pet)
        save()
    }

    /// Delete a pet and all its care plans, occurrences, records, and pending
    /// notifications. This is the safe entry point for "remove a pet"; it
    /// guarantees no orphan notifications continue to fire for a pet the user
    /// no longer tracks.
    func deletePet(_ petId: UUID) {
        let affectedPlanIds = carePlans.filter { $0.petId == petId }.map { $0.id }
        pets.removeAll { $0.id == petId }
        carePlans.removeAll { $0.petId == petId }
        occurrences.removeAll { $0.petId == petId }
        records.removeAll { $0.petId == petId }
        cancelNotifications(for: affectedPlanIds)
        save()
    }

    /// Delete a single care plan and its pending notifications + occurrences.
    func deleteCarePlan(_ planId: UUID) {
        carePlans.removeAll { $0.id == planId }
        occurrences.removeAll { $0.planId == planId }
        cancelNotifications(for: [planId])
        save()
    }

    private func cancelNotifications(for planIds: [UUID]) {
        // Direct UNUserNotificationCenter access keeps AppState free of a hard
        // dependency on NotificationService while still preventing orphan
        // reminders after delete.
        let center = UNUserNotificationCenter.current()
        let identifiers = planIds.flatMap { id in
            [id.uuidString, "\(id.uuidString).snooze"]
        }
        if !identifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }
    }

    func markDone(_ occurrence: CareOccurrence) {
        guard let plan = plan(for: occurrence.planId) else { return }
        let caregiver = currentCaregiverName
        updateOccurrence(occurrence.id) { item in
            item.status = .done
            item.completedAt = Date()
            item.completedBy = caregiver
        }
        appendRecord(
            petId: occurrence.petId,
            type: plan.type.recordType,
            title: "\(plan.name) done",
            value: plan.detail,
            note: "Completed by \(caregiver)"
        )
        save()
    }

    func markDone(planId: UUID) {
        guard let index = activeOccurrenceIndex(forPlanId: planId) else { return }
        let occurrence = occurrences[index]
        let plan = self.plan(for: planId)
        occurrences[index].status = .done
        occurrences[index].completedAt = Date()
        occurrences[index].completedBy = currentCaregiverName
        if let plan {
            appendRecord(
                petId: occurrence.petId,
                type: plan.type.recordType,
                title: "\(plan.name) done",
                value: plan.detail,
                note: "Completed from notification reminder"
            )
        }
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
        guard let plan = plan(for: occurrence.planId) else { return }
        let caregiver = currentCaregiverName
        updateOccurrence(occurrence.id) { item in
            item.status = .skipped
            item.skipReason = reason
            item.completedAt = Date()
            item.completedBy = caregiver
        }
        appendRecord(
            petId: occurrence.petId,
            type: plan.type.recordType,
            title: "\(plan.name) skipped",
            value: reason,
            note: "Skipped by \(caregiver)"
        )
        save()
    }

    private var currentCaregiverName: String {
        // No account system. Use a generic label so completion records read sensibly without
        // a fabricated user name like "Alex".
        "Caregiver"
    }

    func addCarePlan(_ plan: CarePlan) {
        carePlans.append(plan)
        occurrences.append(
            CareOccurrence(planId: plan.id, petId: plan.petId, dueAt: plan.nextDueDate(), status: .due)
        )
        save()
    }

    func exportJSONString() -> String {
        let snapshot = AppSnapshot(pets: pets, carePlans: carePlans, occurrences: occurrences, records: records)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot),
              let text = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return text
    }

    func deleteLocalData() {
        pets = []
        carePlans = []
        occurrences = []
        records = []
        storage.delete()
        // Wipe every scheduled and delivered reminder so the OS does not fire
        // notifications for plans that no longer exist anywhere in the app.
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func save() {
        storage.save(AppSnapshot(pets: pets, carePlans: carePlans, occurrences: occurrences, records: records))
    }

    private func updateOccurrence(_ id: UUID, mutate: (inout CareOccurrence) -> Void) {
        guard let index = occurrences.firstIndex(where: { $0.id == id }) else { return }
        mutate(&occurrences[index])
    }

    private func appendRecord(petId: UUID, type: RecordType, title: String, value: String?, note: String) {
        records.append(
            CareRecord(
                petId: petId,
                type: type,
                date: Date(),
                title: title,
                value: value,
                note: note
            )
        )
    }

    private func activeOccurrenceIndex(forPlanId planId: UUID) -> Int? {
        occurrences
            .enumerated()
            .filter { $0.element.planId == planId && $0.element.status != .done && $0.element.status != .skipped }
            .min { $0.element.dueAt < $1.element.dueAt }?
            .offset
    }
}

private extension CareType {
    var recordType: RecordType {
        switch self {
        case .medicine: .medicine
        case .food: .food
        case .weight: .weight
        case .visit: .visit
        case .vaccine: .vaccine
        }
    }
}
