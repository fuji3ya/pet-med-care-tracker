import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var store: SubscriptionStore
    @State private var showPaywall = false
    @State private var showDeleteConfirmation = false
    var replayOnboarding: () -> Void = {}

    var body: some View {
        List {
            Section("Reminders") {
                HStack {
                    Label("Notifications", systemImage: "bell")
                    Spacer()
                    Text(notificationText)
                        .foregroundStyle(TPColor.muted)
                }
                Button("Enable notifications") {
                    Task { _ = await notifications.requestAuthorization() }
                }
                Button("Test notification") {
                    Task {
                        if notifications.authorizationStatus == .notDetermined {
                            _ = await notifications.requestAuthorization()
                        }
                        if notifications.isAuthorized {
                            await notifications.scheduleTestNotification()
                        }
                    }
                }
            }

            Section("Subscription") {
                Button(store.hasPlus ? "Manage Tend Pets Plus" : "Upgrade to Plus") {
                    showPaywall = true
                }
                Button("Restore Purchase") {
                    Task { await store.refreshEntitlements() }
                }
            }

            Section("Data & Privacy") {
                Button("Replay onboarding") {
                    replayOnboarding()
                }
                ShareLink(item: appState.exportJSONString()) {
                    Label("Export data", systemImage: "square.and.arrow.up")
                }
                NavigationLink("Medical disclaimer") {
                    Text("Tend Pets helps you record and remember care routines. It does not provide veterinary medical advice. Always follow your veterinarian's instructions.")
                        .padding()
                        .navigationTitle("Disclaimer")
                }
            }

            Section("Legal & Support") {
                NavigationLink("Privacy Policy") {
                    LegalTextView(
                        title: "Privacy Policy",
                        content: "Tend Pets stores pet care records, reminder times, notes, and completion history to show reminders and summaries. Subscription purchases are handled by Apple. Tend Pets does not sell personal data or provide veterinary advice."
                    )
                }
                NavigationLink("Terms of Use") {
                    LegalTextView(
                        title: "Terms of Use",
                        content: "Subscriptions renew automatically unless cancelled in App Store account settings. Reminder delivery can be affected by device settings and operating system behavior. Tend Pets is a record and reminder tool, not veterinary advice."
                    )
                }
                Link("Contact Support", destination: URL(string: "mailto:support@tendpets.app")!)
                Button("Delete account", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .confirmationDialog("Delete account?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete local prototype data", role: .destructive) {
                appState.deleteLocalData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The production app must remove cloud data too. This prototype keeps the destructive action behind confirmation.")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
        .alert("Tend Pets Plus", isPresented: Binding(
            get: { store.message != nil },
            set: { if !$0 { store.message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.message ?? "")
        }
    }

    private var notificationText: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: "On"
        case .denied: "Off"
        case .notDetermined: "Not set"
        @unknown default: "Unknown"
        }
    }
}

struct PaywallView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Keep every routine organized")
                    .font(.largeTitle.weight(.bold))
                Text("For pets with daily care, shared routines, and vet-ready records.")
                    .foregroundStyle(TPColor.muted)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Unlimited reminders", systemImage: "bell")
                    Label("Vet summary export", systemImage: "doc.text")
                    Label("Cloud backup", systemImage: "icloud")
                    Label("Up to 5 pets", systemImage: "pawprint")
                }
                .font(.headline)

                if store.isLoading {
                    ProgressView("Loading subscriptions")
                        .foregroundStyle(TPColor.muted)
                } else if store.products.isEmpty {
                    Text("Subscriptions are unavailable. You can still use the free care tracker.")
                        .foregroundStyle(TPColor.muted)
                } else {
                    ForEach(store.products, id: \.id) { product in
                        Button {
                            Task { await store.purchase(product) }
                        } label: {
                            HStack {
                                Text(product.displayName)
                                Spacer()
                                Text(product.displayPrice)
                            }
                        }
                        .buttonStyle(NeutralPillButtonStyle())
                        .accessibilityHint("Starts an App Store purchase sheet.")
                    }
                }

                Button("Restore Purchase") {
                    Task { await store.refreshEntitlements() }
                }
                .buttonStyle(NeutralPillButtonStyle())

                VStack(alignment: .leading, spacing: 6) {
                    Text("Subscription terms")
                        .font(.footnote.weight(.bold))
                    Text("Payment is charged to your Apple ID. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in App Store account settings.")
                    Text("Tend Pets helps organize reminders and records. It does not provide veterinary medical advice.")
                }
                .font(.footnote)
                .foregroundStyle(TPColor.muted)

                Spacer()
            }
            .padding()
            .navigationTitle("Tend Pets Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

struct LegalTextView: View {
    var title: String
    var content: String

    var body: some View {
        ScrollView {
            Text(content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(TPColor.groupedBackground)
    }
}
