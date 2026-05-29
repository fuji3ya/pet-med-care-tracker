import SwiftUI

private enum AppTab: Hashable {
    case today
    case pets
    case add
    case records
    case settings
}

struct RootView: View {
    @AppStorage("tendPetsOnboardingComplete") private var onboardingComplete = false
    @State private var selectedTab: AppTab = .today
    @State private var showOnboarding = false
    @State private var hasCheckedFirstLaunch = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "checkmark.circle")
            }
            .tag(AppTab.today)

            NavigationStack {
                PetsView()
            }
            .tabItem {
                Label("Pets", systemImage: "pawprint")
            }
            .tag(AppTab.pets)

            NavigationStack {
                AddCareView()
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle.fill")
            }
            .tag(AppTab.add)

            NavigationStack {
                RecordsView()
            }
            .tabItem {
                Label("Records", systemImage: "folder")
            }
            .tag(AppTab.records)

            NavigationStack {
                SettingsView {
                    showOnboarding = true
                }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
        .tint(TPColor.primary)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(
                isReplay: onboardingComplete,
                onSkip: {
                    onboardingComplete = true
                    selectedTab = .today
                    showOnboarding = false
                },
                onFinish: {
                    onboardingComplete = true
                    selectedTab = .add
                    showOnboarding = false
                }
            )
        }
        .task {
            // First-launch only — `task` fires once when the view first appears.
            // Using onAppear would re-fire on every tab switch and pop the
            // onboarding sheet back open after the user dismissed it.
            guard !hasCheckedFirstLaunch else { return }
            hasCheckedFirstLaunch = true
            if !onboardingComplete {
                showOnboarding = true
            }
        }
    }
}
