import SwiftUI
import UIKit

/// Resolves a `Pet.photoName` to a real image. Demo pets reference a bundled
/// asset-catalog name (e.g. "demo-cat"); user-added pets reference a file saved
/// in the app's Documents directory. Returns nil when no photo is set.
enum PetImageStore {
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func image(named photoName: String?) -> UIImage? {
        guard let photoName, !photoName.isEmpty else { return nil }
        if let bundled = UIImage(named: photoName) { return bundled }
        let fileURL = documentsDirectory.appendingPathComponent(photoName)
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }

    /// Persist user-picked image data as a JPEG in Documents, returning the
    /// filename to store in `Pet.photoName`. Returns nil on failure.
    @discardableResult
    static func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = "pet-\(UUID().uuidString).jpg"
        let url = documentsDirectory.appendingPathComponent(filename)
        do {
            try jpeg.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }
}

enum TPColor {
    static let background = Color(red: 0.980, green: 0.976, blue: 0.965)
    static let groupedBackground = Color(red: 0.949, green: 0.949, blue: 0.969)
    static let surface = Color.white
    static let text = Color(red: 0.122, green: 0.141, blue: 0.125)
    static let muted = Color(red: 0.431, green: 0.455, blue: 0.435)
    static let primary = Color(red: 0.184, green: 0.435, blue: 0.369)
    static let primarySoft = Color(red: 0.863, green: 0.914, blue: 0.890)
    static let medicine = Color(red: 0.243, green: 0.435, blue: 0.714)
    static let food = Color(red: 0.722, green: 0.475, blue: 0.176)
    static let visit = Color(red: 0.478, green: 0.365, blue: 0.710)
    static let alert = Color(red: 0.722, green: 0.455, blue: 0.227)
}

extension CareType {
    var tint: Color {
        switch self {
        case .medicine: TPColor.medicine
        case .food: TPColor.food
        case .weight: TPColor.primary
        case .visit, .vaccine: TPColor.visit
        }
    }

    var careIcon: String {
        switch self {
        case .medicine: "pills"
        case .food: "fork.knife"
        case .weight: "scalemass"
        case .visit: "cross.case"
        case .vaccine: "syringe"
        }
    }
}

struct CareRingView: View {
    var progress: Double
    var initial: String
    var photoName: String? = nil
    var tint: Color = TPColor.primary

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if let uiImage = PetImageStore.image(named: photoName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(LinearGradient(colors: [tint.opacity(0.75), tint], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(6)
                Text(initial)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 54, height: 54)
        .accessibilityLabel("Care progress \(Int(progress * 100)) percent")
    }
}

struct SectionHeader: View {
    var title: String

    var body: some View {
        Text(title.uppercased())
            .font(.footnote.weight(.semibold))
            .foregroundStyle(TPColor.muted)
            .padding(.horizontal, 4)
            .padding(.top, 8)
    }
}

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(TPColor.primary)
                .frame(width: 44, height: 44)
                .background(TPColor.primarySoft, in: Circle())

            Text(title)
                .font(.headline)
                .foregroundStyle(TPColor.text)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(TPColor.muted)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryPillButtonStyle())
                    .padding(.top, 4)
                    .accessibilityLabel(actionTitle)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
