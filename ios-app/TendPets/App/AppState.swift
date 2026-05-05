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
        guard let plan = plan(for: occurrence.planId) else { return }
        updateOccurrence(occurrence.id) { item in
            item.status = .done
            item.completedAt = Date()
            item.completedBy = "Alex"
        }
        appendRecord(
            petId: occurrence.petId,
            type: plan.type.recordType,
            title: "\(plan.name) done",
            value: plan.detail,
            note: "Completed by Alex"
        )
        save()
    }

    func markDone(planId: UUID) {
        guard let index = activeOccurrenceIndex(forPlanId: planId) else { return }
        let occurrence = occurrences[index]
        let plan = self.plan(for: planId)
        occurrences[index].status = .done
        occurrences[index].completedAt = Date()
        occurrences[index].completedBy = "Notification"
        if let plan {
            appendRecord(
                petId: occurrence.petId,
                type: plan.type.recordType,
                title: "\(plan.name) done",
                value: plan.detail,
                note: "Completed from notification"
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
        updateOccurrence(occurrence.id) { item in
            item.status = .skipped
            item.skipReason = reason
            item.completedAt = Date()
            item.completedBy = "Alex"
        }
        appendRecord(
            petId: occurrence.petId,
            type: plan.type.recordType,
            title: "\(plan.name) skipped",
            value: reason,
            note: "Skipped by Alex"
        )
        save()
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
