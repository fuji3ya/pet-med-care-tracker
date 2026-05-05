import SwiftUI

enum PreviewDevices {
    static let canonical = "iPhone 15"
}

#Preview("Today - iPhone 15") {
    let appState = AppState()
    TodayView()
        .environmentObject(appState)
        .previewDevice(PreviewDevice(rawValue: PreviewDevices.canonical))
}

#Preview("Root - iPhone 15") {
    RootView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionStore())
        .environmentObject(NotificationService())
        .previewDevice(PreviewDevice(rawValue: PreviewDevices.canonical))
}

#Preview("Onboarding - iPhone 15") {
    OnboardingView(isReplay: false, onSkip: {}, onFinish: {})
        .previewDevice(PreviewDevice(rawValue: PreviewDevices.canonical))
}
