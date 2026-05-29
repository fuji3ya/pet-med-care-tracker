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
        // Force Gregorian calendar so age stays correct for users whose device
        // locale uses Buddhist (Thai), Hijri (Saudi), or other non-Gregorian
        // calendars. birthYear is stored as a Gregorian year value.
        let year = Calendar(identifier: .gregorian).component(.year, from: Date())
        let age = max(year - birthYear, 0)
        return "\(species.rawValue) — \(age) year\(age == 1 ? "" : "s")"
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
    case onDate = "On the chosen date"

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
    /// Used when `repeatRule == .onDate` — fires once on this calendar date at
    /// (timeHour, timeMinute). Required for vaccine / vet visit reminders that
    /// are typically scheduled weeks or months in the future.
    var specificDate: Date?
    var notificationEnabled = true
    var active = true

    func nextDueDate() -> Date {
        let calendar = Calendar.current
        let baseDate: Date = {
            switch repeatRule {
            case .daily:
                return Date()
            case .onDate:
                return specificDate ?? Date()
            }
        }()
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = timeHour
        components.minute = timeMinute
        return calendar.date(from: components) ?? baseDate
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
