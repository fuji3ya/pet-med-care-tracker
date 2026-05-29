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
    /// True only for the first-launch sample pet. Sample pets do NOT count toward
    /// the free 1-pet limit and are auto-removed when the user adds their own pet.
    var isSample: Bool = false

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
    /// Doses left in the current supply (Plus refill tracking). nil = not tracked.
    /// Decrements each time a medicine reminder is marked done; warns when low.
    var supplyRemaining: Int?

    /// Low-supply warning threshold (doses). Below or equal -> "refill soon".
    static let lowSupplyThreshold = 3

    var isLowSupply: Bool {
        guard let supplyRemaining else { return false }
        return supplyRemaining <= Self.lowSupplyThreshold
    }

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
    case symptom
}

enum SymptomSeverity: String, Codable, CaseIterable, Identifiable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"

    var id: String { rawValue }
}

struct CareRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var petId: UUID
    var type: RecordType
    var date: Date
    var title: String
    var value: String?
    var note: String
    /// Filename in Documents of an attached photo/document (Plus "vet binder":
    /// vaccine certs, lab results, symptom photos). nil = no attachment.
    var attachmentName: String?

    /// Parse a leading numeric value out of `value` (e.g. "4.2 kg" -> 4.2).
    /// Used to build the weight trend chart from weight records.
    var numericValue: Double? {
        guard let value else { return nil }
        let scanner = Scanner(string: value)
        scanner.charactersToBeSkipped = CharacterSet.whitespaces
        if let d = scanner.scanDouble() { return d }
        return nil
    }
}
