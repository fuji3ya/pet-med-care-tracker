import Foundation

struct AppSnapshot: Codable {
    var pets: [Pet]
    var carePlans: [CarePlan]
    var occurrences: [CareOccurrence]
    var records: [CareRecord]

    static let empty = AppSnapshot(pets: [], carePlans: [], occurrences: [], records: [])
}

final class LocalStorage {
    private let key = "tendpets.snapshot.v1"

    private let corruptedBackupKey = "tendpets.snapshot.v1.corrupted-backup"

    func load() -> AppSnapshot {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return .empty
        }

        do {
            return try JSONDecoder().decode(AppSnapshot.self, from: data)
        } catch {
            // Preserve the corrupted blob so the user (or support) can recover
            // it manually instead of silently losing all care history on a
            // schema mismatch or partial write.
            UserDefaults.standard.set(data, forKey: corruptedBackupKey)
            return .empty
        }
    }

    func save(_ snapshot: AppSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            assertionFailure("Failed to save local snapshot: \(error)")
        }
    }

    func delete() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
