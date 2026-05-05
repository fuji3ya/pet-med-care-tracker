import SwiftUI

@main
struct TendPetsApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store = SubscriptionStore()
    @StateObject private var notifications = NotificationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(store)
                .environmentObject(notifications)
                .task {
                    await store.start()
                    notifications.refreshAuthorizationStatus()
                    notifications.configureActionHandler { action in
                        switch action {
                        case .done(let planId):
                            appState.markDone(planId: planId)
                        case .snooze(let planId, let minutes):
                            appState.snooze(planId: planId, minutes: minutes)
                            if let plan = appState.plan(for: planId),
                               let pet = appState.pet(for: plan.petId) {
                                Task {
                                    await notifications.scheduleSnooze(plan: plan, pet: pet, minutes: minutes)
                                }
                            }
                        case .opened:
                            break
                        }
                    }
                }
        }
    }
}
