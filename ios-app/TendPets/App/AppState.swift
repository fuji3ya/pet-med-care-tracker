import Foundation
import UserNotifications

@MainActor
final class AppState: ObservableObject {
    @Published var pets: [Pet]
    @Published var carePlans: [CarePlan]
    @Published var occurrences: [CareOccurrence]
    @Published var records: [CareRecord]
    /// Set when onboarding finishes so the Pets tab immediately opens the
    /// "Add your pet" sheet — the first real action is adding the user's own pet.
    @Published var requestAddPet = false

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

    /// First-launch SAMPLE data so the app never opens empty. ONE sample pet
    /// (clearly badged "SAMPLE" in the UI) with photo, reminders, and history so
    /// every screen feels real. The sample does NOT count toward the free 1-pet
    /// limit and is auto-removed the moment the user adds their own pet, so a new
    /// free user never hits a paywall just to add their first pet.
    private func seedDemoData() {
        let cat = Pet(name: "Momo", species: .cat, birthYear: 2014,
                      weightValue: 4.2, weightUnit: .kg, photoName: "demo-cat", isSample: true)
        pets = [cat]

        var catMed = CarePlan(petId: cat.id, type: .medicine, name: "Heart med",
                              detail: "1 tablet, after breakfast",
                              timeHour: 8, timeMinute: 0, repeatRule: .daily)
        catMed.supplyRemaining = 4  // showcases Plus refill tracking on the sample
        let catWeight = CarePlan(petId: cat.id, type: .weight, name: "Weight check",
                                 detail: "Weigh on the kitchen scale",
                                 timeHour: 9, timeMinute: 0, repeatRule: .daily)
        carePlans = [catMed, catWeight]

        let cal = Calendar.current
        let now = Date()
        let eightToday = cal.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        let laterToday = cal.date(byAdding: .hour, value: 3, to: now) ?? now
        occurrences = [
            CareOccurrence(planId: catMed.id, petId: cat.id, dueAt: eightToday, status: .due),
            CareOccurrence(planId: catWeight.id, petId: cat.id, dueAt: laterToday, status: .upcoming),
        ]

        func daysAgo(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now) ?? now }
        records = [
            CareRecord(petId: cat.id, type: .medicine, date: daysAgo(1),
                       title: "Heart med done", value: "1 tablet", note: "Completed by Caregiver"),
            CareRecord(petId: cat.id, type: .weight, date: daysAgo(12),
                       title: "Weight check", value: "4.3 kg", note: "Steady"),
            CareRecord(petId: cat.id, type: .weight, date: daysAgo(3),
                       title: "Weight check", value: "4.2 kg", note: "Slight loss — mention to vet"),
            CareRecord(petId: cat.id, type: .vaccine, date: daysAgo(40),
                       title: "Rabies vaccine", value: "Lot 22-118", note: "Annual booster"),
        ]
    }

    /// Pets the user actually created (excludes the first-launch sample).
    var realPetCount: Int {
        pets.filter { !$0.isSample }.count
    }

    /// Remove every sample pet and its data. Called automatically when the user
    /// adds their own pet, so the sample is seamlessly replaced.
    private func removeSamplePets() {
        for sample in pets.filter({ $0.isSample }) {
            let planIds = carePlans.filter { $0.petId == sample.id }.map { $0.id }
            carePlans.removeAll { $0.petId == sample.id }
            occurrences.removeAll { $0.petId == sample.id }
            records.removeAll { $0.petId == sample.id }
            cancelNotifications(for: planIds)
        }
        pets.removeAll { $0.isSample }
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
    //
    // Reminders are UNLIMITED on the free tier (matches the strongest competitor,
    // PillPaw). Free is intentionally a complete single-pet habit-builder; Plus
    // unlocks multiple pets, full history, the vet summary (charts + PDF), and
    // data export.

    static let freeMaxPets = 1

    func canAddPet(hasPlus: Bool) -> Bool {
        // Sample pets don't count — a new free user can always add their first
        // real pet (the sample is replaced), never blocked by a paywall.
        hasPlus || realPetCount < Self.freeMaxPets
    }

    /// Reminders are unlimited for everyone now. Kept as a method so call sites
    /// stay stable if a cap is ever reintroduced.
    func canAddCarePlan(hasPlus: Bool) -> Bool {
        true
    }

    var activeCarePlanCount: Int {
        carePlans.filter { $0.active }.count
    }

    /// A pet's own care history is never gated — for 1 pet it stays free and
    /// permanent. Monetization is value-add (multi-pet, vet PDF, refill alerts),
    /// not holding the user's data hostage. `hasPlus` kept for call-site stability.
    func recordsVisibleToUser(hasPlus: Bool) -> [CareRecord] {
        records
    }

    func addPet(_ pet: Pet) {
        // Adding a real pet replaces the first-launch sample(s).
        if !pet.isSample {
            removeSamplePets()
        }
        pets.append(pet)
        save()
    }

    /// Replace an existing pet (edit name, species, weight, photo, etc.).
    func updatePet(_ pet: Pet) {
        guard let idx = pets.firstIndex(where: { $0.id == pet.id }) else { return }
        pets[idx] = pet
        save()
    }

    /// Replace an existing care plan and re-point its active (not-yet-completed)
    /// occurrence to the new schedule. Caller is responsible for rescheduling the
    /// local notification.
    func updateCarePlan(_ plan: CarePlan) {
        guard let idx = carePlans.firstIndex(where: { $0.id == plan.id }) else { return }
        carePlans[idx] = plan
        if let occIdx = occurrences.firstIndex(where: { $0.planId == plan.id && $0.status != .done && $0.status != .skipped }) {
            occurrences[occIdx].dueAt = plan.nextDueDate()
        }
        save()
    }

    // MARK: - Ad-hoc logging (no reminder needed)

    /// Log a one-off record (weight, symptom, note) directly to history.
    func logRecord(petId: UUID, type: RecordType, title: String, value: String?, note: String, date: Date = Date()) {
        records.append(CareRecord(petId: petId, type: type, date: date, title: title, value: value, note: note))
        save()
    }

    func logWeight(petId: UUID, value: Double, unit: WeightUnit, date: Date = Date(), note: String = "") {
        // Is this the most recent weight reading for the pet? Only then should it
        // become the pet's headline weight — logging an older measurement must not
        // overwrite a newer "current" weight.
        let isLatest = records
            .filter { $0.petId == petId && $0.type == .weight }
            .allSatisfy { $0.date <= date }

        let formatted = "\(value.formatted(.number.precision(.fractionLength(0...1)))) \(unit.rawValue)"
        logRecord(petId: petId, type: .weight, title: "Weight check", value: formatted, note: note, date: date)

        if isLatest, let idx = pets.firstIndex(where: { $0.id == petId }) {
            pets[idx].weightValue = value
            pets[idx].weightUnit = unit
            save()
        }
    }

    func logSymptom(petId: UUID, name: String, severity: SymptomSeverity, note: String, date: Date = Date()) {
        logRecord(petId: petId, type: .symptom, title: name, value: severity.rawValue, note: note, date: date)
    }

    /// Weight records for a pet, oldest-first, with a parsed numeric value (for charts).
    func weightSeries(for petId: UUID) -> [(date: Date, value: Double)] {
        records
            .filter { $0.petId == petId && $0.type == .weight }
            .compactMap { rec -> (date: Date, value: Double)? in
                guard let v = rec.numericValue else { return nil }
                return (date: rec.date, value: v)
            }
            .sorted { $0.date < $1.date }
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
        decrementSupply(forPlanId: occurrence.planId)
        save()
    }

    /// Decrement a medicine plan's tracked supply when a dose is given (Plus
    /// refill tracking). No-op for plans that don't track supply.
    func decrementSupply(forPlanId planId: UUID) {
        guard let idx = carePlans.firstIndex(where: { $0.id == planId }),
              carePlans[idx].type == .medicine,
              let remaining = carePlans[idx].supplyRemaining else { return }
        carePlans[idx].supplyRemaining = max(0, remaining - 1)
    }

    /// Active medicine plans that are running low on supply (Plus).
    var lowSupplyPlans: [CarePlan] {
        carePlans.filter { $0.active && $0.type == .medicine && $0.isLowSupply }
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
        decrementSupply(forPlanId: planId)
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
