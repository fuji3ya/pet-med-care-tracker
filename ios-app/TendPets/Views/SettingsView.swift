import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var store: SubscriptionStore
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
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
                if let days = store.trialDaysLeft {
                    HStack {
                        Label("Plus free trial", systemImage: "sparkles")
                        Spacer()
                        Text(days == 1 ? "1 day left" : "\(days) days left")
                            .foregroundStyle(TPColor.muted)
                    }
                }
                Button(store.hasPlus ? "Manage Tend Pets Plus" : "Upgrade to Plus") {
                    // Subscribers go to Apple's manage-subscriptions sheet (cancel /
                    // switch plan); non-subscribers see the in-app paywall.
                    if store.hasPlus {
                        showManageSubscriptions = true
                    } else {
                        showPaywall = true
                    }
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
                NavigationLink("Medical disclaimer & sources") {
                    MedicalSafetyView()
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
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
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

    enum Tier: String, CaseIterable, Identifiable {
        case plus = "Plus"
        case family = "Family"
        var id: String { rawValue }
    }

    @State private var tier: Tier = .plus
    @State private var selectedProductId: String?

    private static let termsURL = URL(string: "https://tendpets.starving-effort.com/terms")!
    private static let privacyURL = URL(string: "https://tendpets.starving-effort.com/privacy")!

    // MARK: - Product helpers

    private func product(_ tier: Tier, yearly: Bool) -> Product? {
        let id: String
        switch (tier, yearly) {
        case (.plus, true): id = SubscriptionStore.ProductId.plusYearly
        case (.plus, false): id = SubscriptionStore.ProductId.plusMonthly
        case (.family, true): id = SubscriptionStore.ProductId.familyYearly
        case (.family, false): id = SubscriptionStore.ProductId.familyMonthly
        }
        return store.products.first { $0.id == id }
    }

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedProductId }
    }

    private var selectedIsYearly: Bool {
        selectedProductId?.hasSuffix(".yearly") ?? false
    }

    /// Default the selection to the current tier's yearly plan when none is set
    /// or the current one no longer matches the visible tier.
    private func setDefaultSelection() {
        let yearlyId = product(tier, yearly: true)?.id
        let monthlyId = product(tier, yearly: false)?.id
        if selectedProductId == nil || (selectedProductId != yearlyId && selectedProductId != monthlyId) {
            selectedProductId = yearlyId ?? monthlyId
        }
    }

    private func perMonthLabel(_ product: Product) -> String {
        (product.price / 12).formatted(product.priceFormatStyle)
    }

    private func savingsPercent(_ tier: Tier) -> Int? {
        guard let yearly = product(tier, yearly: true),
              let monthly = product(tier, yearly: false) else { return nil }
        let yearOfMonthly = monthly.price * 12
        guard yearOfMonthly > 0 else { return nil }
        let saved = 1 - (NSDecimalNumber(decimal: yearly.price).doubleValue
                         / NSDecimalNumber(decimal: yearOfMonthly).doubleValue)
        let pct = Int((saved * 100).rounded())
        return pct > 0 ? pct : nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    heroSection
                    featureList
                    Picker("Plan tier", selection: $tier) {
                        ForEach(Tier.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    planSection
                    ctaSection
                    termsSection
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(TPColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(TPColor.muted)
                    }
                    .disabled(store.isPurchasing)
                    .accessibilityLabel("Close")
                }
            }
            .onAppear { setDefaultSelection() }
            .onChange(of: tier) { _, _ in setDefaultSelection() }
            .onChange(of: store.products.map(\.id)) { _, _ in setDefaultSelection() }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.235, green: 0.510, blue: 0.439), TPColor.primary],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 84, height: 84)
                .overlay(
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: TPColor.primary.opacity(0.35), radius: 12, y: 6)

            Text("TEND PETS PLUS")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(TPColor.primary)

            Text("Everything your pet's care needs, in one place")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Refill alerts, vet-ready summaries, and routines for every pet you love.")
                .font(.subheadline)
                .foregroundStyle(TPColor.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow("pawprint.fill", TPColor.primary, "Unlimited pets — free keeps 1 with full history")
            featureRow("pills.fill", TPColor.medicine, "Medication refill tracking + low-supply alerts")
            featureRow("doc.text.fill", TPColor.visit, "Vet summary: weight chart + PDF for the vet")
            featureRow("paperclip", TPColor.food, "Photo & document attachments (vet binder)")
            featureRow("clock.arrow.2.circlepath", TPColor.alert, "Twice / 3× daily medication schedules")
        }
    }

    @ViewBuilder
    private func featureRow(_ icon: String, _ tint: Color, _ text: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(text)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var planSection: some View {
        if store.isLoading {
            ProgressView("Loading subscriptions")
                .foregroundStyle(TPColor.muted)
                .frame(maxWidth: .infinity)
        } else if store.products.isEmpty {
            Text("Subscriptions are unavailable. You can still use the free care tracker.")
                .font(.subheadline)
                .foregroundStyle(TPColor.muted)
        } else {
            VStack(spacing: 12) {
                if let yearly = product(tier, yearly: true) {
                    planCard(yearly, isYearly: true)
                }
                if let monthly = product(tier, yearly: false) {
                    planCard(monthly, isYearly: false)
                }
            }
        }
    }

    @ViewBuilder
    private func planCard(_ product: Product, isYearly: Bool) -> some View {
        let selected = selectedProductId == product.id
        Button {
            selectedProductId = product.id
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? TPColor.primary : Color(.systemGray3), lineWidth: 2)
                    if selected {
                        Circle().fill(TPColor.primary)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(TPColor.text)
                    Text(isYearly ? "\(perMonthLabel(product)) / mo" : "billed monthly")
                        .font(.caption)
                        .foregroundStyle(TPColor.muted)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(product.displayPrice)
                        .font(.body.weight(.bold))
                        .foregroundStyle(TPColor.text)
                    Text(isYearly ? "/ year" : "/ month")
                        .font(.caption2)
                        .foregroundStyle(TPColor.muted)
                }
            }
            .padding(16)
            .background(selected ? TPColor.primarySoft.opacity(0.55) : TPColor.surface,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selected ? TPColor.primary : Color(.systemGray5),
                                  lineWidth: selected ? 1.6 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isYearly, let pct = savingsPercent(tier) {
                    Text("SAVE \(pct)%")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(TPColor.primary, in: Capsule())
                        .offset(x: -14, y: -9)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(store.isPurchasing)
    }

    /// Honest one-line explainer under the CTA, matching the customer's state.
    private func ctaSubtext(_ product: Product) -> String {
        let period = selectedIsYearly ? "/ year" : "/ month"
        if store.introOfferEligible {
            return "1 month free, then \(product.displayPrice) \(period). Cancel anytime."
        } else {
            return "\(product.displayPrice) \(period). Cancel anytime."
        }
    }

    private var ctaSection: some View {
        VStack(spacing: 10) {
            Button {
                guard let product = selectedProduct else { return }
                Task {
                    await store.purchase(product)
                    if store.hasPlus { dismiss() }
                }
            } label: {
                if store.isPurchasing {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Processing…")
                    }
                } else {
                    // State-aware: only promise a free month when the customer is
                    // actually eligible for the intro offer; otherwise it's a
                    // straight subscribe.
                    Text(store.introOfferEligible ? "Start my free month" : "Subscribe")
                }
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .disabled(selectedProduct == nil || store.isPurchasing)

            if let product = selectedProduct {
                Text(ctaSubtext(product))
                    .font(.footnote)
                    .foregroundStyle(TPColor.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Restore Purchase") {
                Task {
                    await store.refreshEntitlements()
                    if store.hasPlus { dismiss() }
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TPColor.primary)
            .disabled(store.isPurchasing)
        }
        .frame(maxWidth: .infinity)
    }

    private var termsSection: some View {
        VStack(spacing: 6) {
            Text("1-month free trial, then the price shown. Subscriptions auto-renew at the displayed price unless cancelled at least 24 hours before the period ends. Manage or cancel anytime in your Apple ID settings.")
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link("Terms of Use", destination: Self.termsURL)
                Link("Privacy Policy", destination: Self.privacyURL)
            }
        }
        .font(.caption2)
        .foregroundStyle(TPColor.muted)
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }
}

/// Medical disclaimer + citations to reputable veterinary sources.
/// Required by App Store Guideline 1.4.1 for apps that surface health/medical
/// information: the app must (a) state it does not give medical advice and
/// (b) cite easy-to-find authoritative sources.
struct MedicalSafetyView: View {
    private struct Source: Identifiable {
        let id = UUID()
        let name: String
        let detail: String
        let url: URL
    }

    private let sources: [Source] = [
        Source(name: "American Veterinary Medical Association (AVMA)",
               detail: "Pet owner resources on medication, vaccines, and preventive care.",
               url: URL(string: "https://www.avma.org/resources-tools/pet-owners")!),
        Source(name: "American Animal Hospital Association (AAHA)",
               detail: "Canine and feline vaccination guidelines.",
               url: URL(string: "https://www.aaha.org/resources/")!),
        Source(name: "WSAVA Global Vaccination Guidelines",
               detail: "International standards for pet vaccination schedules.",
               url: URL(string: "https://wsava.org/global-guidelines/vaccination-guidelines/")!),
        Source(name: "U.S. FDA — Animal & Veterinary",
               detail: "Approved animal drugs and medication safety information.",
               url: URL(string: "https://www.fda.gov/animal-veterinary")!),
        Source(name: "ASPCA — Pet Care",
               detail: "General pet health and care guidance.",
               url: URL(string: "https://www.aspca.org/pet-care")!),
    ]

    var body: some View {
        List {
            Section {
                Text("Tend Pets is a reminder and record-keeping tool. It does **not** diagnose conditions, recommend medications or dosages, replace veterinary care, or provide emergency guidance. Always follow your veterinarian's instructions, and contact your veterinarian or an emergency animal hospital for any health concern.")
                    .font(.subheadline)
                    .foregroundStyle(TPColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 4)
            } header: {
                Text("Important")
            }

            Section {
                ForEach(sources) { source in
                    Link(destination: source.url) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(source.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(TPColor.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundStyle(TPColor.muted)
                            }
                            Text(source.detail)
                                .font(.caption)
                                .foregroundStyle(TPColor.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Trusted sources")
            } footer: {
                Text("Any health information you record in Tend Pets comes from you and your veterinarian. These independent organizations publish accurate, citable pet-health guidance.")
            }
        }
        .navigationTitle("Disclaimer & sources")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
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
