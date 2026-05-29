import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var store: SubscriptionStore
    @State private var showPaywall = false
    @State private var showDeleteConfirmation = false
    @State private var showNotificationDisabledAlert = false
    var replayOnboarding: () -> Void = {}

    private static let termsURL = URL(string: "https://tendpets.starving-effort.com/terms")!
    private static let privacyURL = URL(string: "https://tendpets.starving-effort.com/privacy")!
    private static let supportURL = URL(string: "https://tendpets.starving-effort.com/support")!

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
                Button("Send test notification") {
                    Task { await sendTestNotification() }
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
                if store.hasPlus {
                    ShareLink(item: appState.exportJSONString()) {
                        Label("Export data", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Label("Export data", systemImage: "square.and.arrow.up")
                            Spacer()
                            Text("Plus")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(TPColor.primarySoft, in: Capsule())
                                .foregroundStyle(TPColor.primary)
                        }
                    }
                }
                NavigationLink("Medical disclaimer") {
                    LegalTextView(
                        title: "Disclaimer",
                        content: "Tend Pets helps you record and remember care routines. It does not diagnose, recommend medication dosage, replace veterinary care, or provide emergency guidance. Always follow your veterinarian's instructions."
                    )
                }
            }

            Section("Legal & Support") {
                Link(destination: Self.privacyURL) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(TPColor.muted)
                    }
                }
                Link(destination: Self.termsURL) {
                    HStack {
                        Text("Terms of Use")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(TPColor.muted)
                    }
                }
                Link(destination: Self.supportURL) {
                    HStack {
                        Text("Support")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(TPColor.muted)
                    }
                }
                Link("Contact support by email", destination: URL(string: "mailto:support@starving-effort.com")!)
                Button("Delete all data", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .confirmationDialog("Delete all data?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete all pet data", role: .destructive) {
                appState.deleteLocalData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes pets, reminders, and records from this device. This cannot be undone.")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
        .alert("Tend Pets", isPresented: Binding(
            get: { store.message != nil },
            set: { if !$0 { store.message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.message ?? "")
        }
        .alert("Notifications are off", isPresented: $showNotificationDisabledAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable notifications in iOS Settings > Notifications > Tend Pets to receive reminders.")
        }
    }

    private var notificationText: String {
        switch notifications.authorizationStatus {
        case .authorized: "On"
        case .provisional: "Quiet delivery"
        case .ephemeral: "Temporary"
        case .denied: "Off"
        case .notDetermined: "Not set"
        @unknown default: "Unknown"
        }
    }

    private func sendTestNotification() async {
        if notifications.authorizationStatus == .notDetermined {
            _ = await notifications.requestAuthorization()
        }
        if notifications.isAuthorized {
            await notifications.scheduleTestNotification()
            store.message = "Test reminder scheduled — you'll see it in about 5 seconds."
        } else {
            showNotificationDisabledAlert = true
        }
    }
}

struct PaywallView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    private static let termsURL = URL(string: "https://tendpets.starving-effort.com/terms")!
    private static let privacyURL = URL(string: "https://tendpets.starving-effort.com/privacy")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Keep every routine organized")
                        .font(.largeTitle.weight(.bold))
                    Text("For pets with daily care, shared routines, and vet-ready records.")
                        .foregroundStyle(TPColor.muted)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Unlimited pets and reminders", systemImage: "pawprint")
                        Label("Full vet summary builder", systemImage: "doc.text")
                        Label("Full care history (free shows last 7 days)", systemImage: "clock.arrow.circlepath")
                        Label("Export all data as JSON", systemImage: "square.and.arrow.up")
                    }
                    .font(.headline)

                    Text("Start with 1 month free. Cancel anytime.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TPColor.primary)

                    if store.isLoading {
                        ProgressView("Loading subscriptions")
                            .foregroundStyle(TPColor.muted)
                    } else if store.products.isEmpty {
                        Text("Subscriptions are unavailable. You can still use the free care tracker.")
                            .foregroundStyle(TPColor.muted)
                    } else {
                        ForEach(store.products, id: \.id) { product in
                            Button {
                                Task {
                                    await store.purchase(product)
                                    if store.hasPlus {
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(product.displayName)
                                    Spacer()
                                    Text(store.isPurchasing ? "Processing…" : product.displayPrice)
                                }
                            }
                            .buttonStyle(NeutralPillButtonStyle())
                            .disabled(store.isPurchasing)
                            .accessibilityHint("Starts an App Store purchase sheet.")
                        }
                    }

                    Button("Restore Purchase") {
                        Task {
                            await store.refreshEntitlements()
                            if store.hasPlus {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(NeutralPillButtonStyle())
                    .disabled(store.isPurchasing)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Subscription terms")
                            .font(.footnote.weight(.bold))
                        Text("Tend Pets Plus and Family are auto-renewing subscriptions. After the 1-month free trial, payment is charged to your Apple ID account at the displayed price. Subscriptions automatically renew at the same price unless cancelled at least 24 hours before the end of the current period. Subscriptions can be managed and auto-renewal turned off in your Apple ID account settings after purchase.")
                        Text("Tend Pets helps organize reminders and records. It does not provide veterinary medical advice.")

                        HStack(spacing: 16) {
                            Link("Terms of Use", destination: Self.termsURL)
                            Link("Privacy Policy", destination: Self.privacyURL)
                        }
                        .padding(.top, 4)
                    }
                    .font(.footnote)
                    .foregroundStyle(TPColor.muted)
                }
                .padding()
            }
            .navigationTitle("Tend Pets Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close") {
                    dismiss()
                }
                .disabled(store.isPurchasing)
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
