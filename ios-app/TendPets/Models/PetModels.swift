import Foundation

enum Species: String, Codable, CaseIterable, Identifiable {
    case dog = "Dog"
    case cat = "Cat"
    case rabbit = "Rabbit"
    case bird = "Bird"
    case reptile = "Reptile"
    case smallMammal = "Small mammal"
    case fish = "Fish"
    case other = "Other"

    var id: String { rawValue }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg
    case lb
    case g

    var id: String { rawValue }
}

struct Pet: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var species: Species
    var birthYear: Int?
    var weightValue: Double?
    var weightUnit: WeightUnit = .kg
    var photoName: String?
    var archivedAt: Date?

    var ageText: String {
        guard let birthYear else { return species.rawValue }
        let year = Calendar.current.component(.year, from: Date())
        return "\(species.rawValue) - \(max(year - birthYear, 0)) years"
    }

    var weightText: String {
        guard let weightValue else { return "No weight" }
        return "\(weightValue.formatted(.number.precision(.fractionLength(0...1)))) \(weightUnit.rawValue)"
    }
}

enum CareType: String, Codable, CaseIterable, Identifiable {
    case medicine = "Medicine"
    case food = "Food"
    case weight = "Weight"
    case visit = "Visit"
    case vaccine = "Vaccine"

    var id: String { rawValue }
}

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case everyXDays = "Every X days"
    case custom = "Custom"

    var id: String { rawValue }
}

struct CarePlan: Identifiable, Codable, Hashable {
    var id = UUID()
    var petId: UUID
    var type: CareType
    var name: String
    var detail: String
    var timeHour: Int
    var timeMinute: Int
    var repeatRule: RepeatRule
    var startDate = Date()
    var endDate: Date?
    var notificationEnabled = true
    var assignedUserName: String?
    var active = true

    func nextDueDate() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = timeHour
        components.minute = timeMinute
        return Calendar.current.date(from: components) ?? Date()
    }
}

enum OccurrenceStatus: String, Codable {
    case upcoming
    case due
    case done
    case skipped
    case missed
}

struct CareOccurrence: Identifiable, Codable, Hashable {
    var id = UUID()
    var planId: UUID
    var petId: UUID
    var dueAt: Date
    var status: OccurrenceStatus
    var completedAt: Date?
    var completedBy: String?
    var skipReason: String?
    var note: String?
}

enum RecordType: String, Codable {
    case weight
    case vaccine
    case visit
    case food
    case note
    case medicine
}

struct CareRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var petId: UUID
    var type: RecordType
    var date: Date
    var title: String
    var value: String?
    var note: String
}
