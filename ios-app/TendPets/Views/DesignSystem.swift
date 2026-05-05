import SwiftUI

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
}

struct CareRingView: View {
    var progress: Double
    var initial: String
    var tint: Color = TPColor.primary

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(LinearGradient(colors: [.brown.opacity(0.75), .brown], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(6)
            Text(initial)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
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
