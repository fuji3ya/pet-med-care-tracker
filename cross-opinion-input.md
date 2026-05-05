# Tend Pets Cross Opinion Review Package


## File: REDACTED-PATH\generated\pet-med-care-tracker\cross-opinion-prompt.md
```md
# Cross Opinion Prompt: Qwen3 / Gemma4

Please review the Tend Pets iOS app direction and source scaffold as if preparing for App Store submission.

Runtime note:

Use local Ollama models for this review:

- Qwen: `qwen3.6:35b-a3b` or `qwen3:8b`
- Gemma: `gemma4:latest`

## Review Scope

Path:

`REDACTED-PATH\generated\pet-med-care-tracker`

Focus especially on:

- `ios-app`
- `prototype/ios-native.html`
- `prototype/ios-native.css`
- `prototype/ios-ui-correction.md`
- `prototype/device-size-standard.md`

## Product

Tend Pets is an iOS-first pet medication and care tracker.

Core jobs:

- Medication reminders
- Vaccine history
- Weight records
- Vet visit notes
- Food notes
- Multi-pet management
- Family care visibility
- Vet Summary PDF

Important safety boundary:

The app must not provide veterinary diagnosis, dosage recommendation, treatment advice, disease prevention claims, or emergency triage.

## Current Design Standard

Canonical iPhone target:

`iPhone 15 logical portrait, 393 x 852 pt`

Native UI should use:

- SwiftUI
- TabView
- NavigationStack
- Large titles
- Grouped List/Form
- Bottom tab bar
- Sheets / confirmation dialogs for contextual actions
- 44pt minimum touch targets

## Questions

1. Does the native iOS UI direction look appropriate for an App Store-quality iPhone app?
2. Are there any remaining web-like or non-native UI patterns?
3. Are the SwiftUI architecture and file boundaries reasonable for the MVP?
4. Are there App Store review risks, especially around medical claims, notifications, privacy, or subscriptions?
5. What must be fixed before attempting TestFlight?
6. What can safely wait until after the first TestFlight build?

Please return:

- Critical blockers
- High-priority fixes
- Medium-priority improvements
- Positive confirmations
- A concise final verdict

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\prototype\device-size-standard.md
```md
# Device Size Standard

## Canonical Design Target

Use one iPhone size for UI decisions:

```text
iPhone 15 logical portrait size
393 x 852 pt
```

## Why This Size

- Modern mainstream iPhone proportion
- Good baseline for App Store screenshots and SwiftUI previews
- Close enough to current iPhone 15/16 class devices for layout decisions
- Avoids the earlier problem where presentation mockups used multiple unrelated phone sizes

## Rules

- Native app UI reference uses `393 x 852`.
- Sales page may show product mockups, but app UI decisions come from the native reference.
- Do not judge real app spacing from the marketing board.
- SwiftUI should remain responsive, but design QA starts from this size.
- After this size passes, test narrow fallback such as iPhone SE.

## Source Files

- `ios-native.html`
- `ios-native.css`
- `ios-native.js`

The CSS defines:

```css
--device-width: 393px;
--device-height: 852px;
```


```


## File: REDACTED-PATH\generated\pet-med-care-tracker\prototype\ios-ui-correction.md
```md
# iPhone UI Correction

## Direct Answer

The previous browser prototype was **not** a correct iPhone app UI. It was a useful product and sales concept board, but it mixed website presentation patterns with app screens.

## What Was Wrong For Native iOS

| Problem | Why it is wrong |
|---|---|
| Web-style pill tabs controlled the app screens | A real iPhone app should use a bottom tab bar or navigation stack, not external chip navigation |
| Screen notes sat beside the phone | Good for presentation, not part of an iOS app |
| Too many floating cards and marketing layout cues | Native iOS favors grouped lists, navigation bars, sheets, and system controls |
| Buttons looked visually nice but were not consistently native | iOS needs 44pt targets and familiar actions |
| Settings looked like a custom web list | Settings should be a grouped iOS list |
| Add Care looked like a web form | It should feel like an iOS grouped form with segmented control and navigation actions |
| Paywall and notifications were conceptually right but too presentation-like | StoreKit and notification permission flows need native states |

## Corrected Direction

Created a separate native iOS reference:

`ios-native.html`

This version uses:

- Bottom tab bar
- Large titles
- Grouped iOS lists
- Native-feeling forms
- Contextual action sheet
- Safe-area-style bottom navigation
- 44pt primary controls

## Fixed Device Size

The native reference now uses one canonical app size:

`iPhone 15 logical portrait, 393 x 852 pt`

Earlier mixed-size phone frames should not be used for judging the actual iOS app.
- Clear separation from sales page UI

## Rule Going Forward

Use `index.html` for sales/marketing presentation.

Use `ios-native.html` as the source of truth for actual iPhone app UI direction.

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\README.md
```md
# Tend Pets iOS App

Native SwiftUI app scaffold for App Store-oriented development.

## What This Is

This is the start of the actual iPhone app implementation, separate from the browser sales prototype.

Included:

- SwiftUI app entry
- Native TabView navigation
- Today, Pets, Add Care, Records, Settings
- Local Codable persistence
- Local notification service
- StoreKit subscription manager
- Paywall skeleton
- Privacy Manifest
- Info.plist
- StoreKit local configuration draft
- App Store metadata draft
- Asset catalog structure
- Canonical iPhone 15 SwiftUI previews

## Generate Xcode Project

This folder uses XcodeGen.

On macOS:

```bash
cd REDACTED-PATH/generated/pet-med-care-tracker/ios-app
brew install xcodegen
xcodegen generate
open TendPets.xcodeproj
```

If the path is on macOS, use the mounted equivalent path instead of the Windows path.

## Before App Store Submission

Required:

- Set `DEVELOPMENT_TEAM` in `project.yml`
- Replace placeholder App Store URLs
- Confirm subscription product IDs in App Store Connect
- Archive on macOS with Xcode
- Test notifications on a physical iPhone
- Test StoreKit purchases in sandbox
- Replace generated app icons with final approved icons if needed
- Add real Privacy Policy and Terms pages

## Canonical Design Size

Use one baseline for design QA:

```text
iPhone 15 logical portrait, 393 x 852 pt
```

SwiftUI remains responsive, but first-pass UI review should use the `iPhone 15` previews in:

```text
TendPets/Views/PreviewDevices.swift
```

## Medical Safety

Do not add diagnosis, dosage recommendation, treatment recommendation, disease prevention claims, or emergency triage features.

Tend Pets is a records and reminders app only.

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\project.yml
```yml
name: TendPets
options:
  bundleIdPrefix: com.tendpets
  deploymentTarget:
    iOS: "17.0"
settings:
  base:
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_TEAM: ""
targets:
  TendPets:
    type: application
    platform: iOS
    sources:
      - TendPets/App
      - TendPets/Models
      - TendPets/Services
      - TendPets/Views
    resources:
      - TendPets/Resources
      - StoreKit
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.tendpets.app
        INFOPLIST_FILE: TendPets/Resources/Info.plist
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        SWIFT_VERSION: "5.9"
    scheme:
      testTargets: []
      storeKitConfiguration: StoreKit/TendPets.storekit

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\App\AppState.swift
```swift
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var pets: [Pet]
    @Published var carePlans: [CarePlan]
    @Published var occurrences: [CareOccurrence]
    @Published var records: [CareRecord]

    private let storage = LocalStorage()

    init() {
        let snapshot = storage.load()
        pets = snapshot.pets
        carePlans = snapshot.carePlans
        occurrences = snapshot.occurrences
        records = snapshot.records

        if pets.isEmpty {
            let sample = Pet(name: "Momo", species: .cat, birthYear: 2014, weightValue: 4.2, weightUnit: .kg)
            pets = [sample]
            let plan = CarePlan(
                petId: sample.id,
                type: .medicine,
                name: "Heart med",
                detail: "1 tablet, after breakfast",
                timeHour: 8,
                timeMinute: 0,
                repeatRule: .daily
            )
            carePlans = [plan]
            occurrences = [
                CareOccurrence(planId: plan.id, petId: sample.id, dueAt: Date(), status: .due)
            ]
        }
    }

    var todaysOccurrences: [CareOccurrence] {
        occurrences.sorted { $0.dueAt < $1.dueAt }
    }

    func pet(for id: UUID) -> Pet? {
        pets.first { $0.id == id }
    }

    func plan(for id: UUID) -> CarePlan? {
        carePlans.first { $0.id == id }
    }

    func markDone(_ occurrence: CareOccurrence) {
        updateOccurrence(occurrence.id) { item in
            item.status = .done
            item.completedAt = Date()
            item.completedBy = "Alex"
        }
        save()
    }

    func skip(_ occurrence: CareOccurrence, reason: String) {
        updateOccurrence(occurrence.id) { item in
            item.status = .skipped
            item.skipReason = reason
            item.completedAt = Date()
            item.completedBy = "Alex"
        }
        save()
    }

    func addCarePlan(_ plan: CarePlan) {
        carePlans.append(plan)
        occurrences.append(
            CareOccurrence(planId: plan.id, petId: plan.petId, dueAt: plan.nextDueDate(), status: .due)
        )
        save()
    }

    func save() {
        storage.save(AppSnapshot(pets: pets, carePlans: carePlans, occurrences: occurrences, records: records))
    }

    private func updateOccurrence(_ id: UUID, mutate: (inout CareOccurrence) -> Void) {
        guard let index = occurrences.firstIndex(where: { $0.id == id }) else { return }
        mutate(&occurrences[index])
    }
}

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\RootView.swift
```swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "checkmark.circle")
            }

            NavigationStack {
                PetsView()
            }
            .tabItem {
                Label("Pets", systemImage: "pawprint")
            }

            NavigationStack {
                AddCareView()
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle.fill")
            }

            NavigationStack {
                RecordsView()
            }
            .tabItem {
                Label("Records", systemImage: "folder")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(TPColor.primary)
    }
}

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\TodayView.swift
```swift
import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @State private var snoozeOccurrence: CareOccurrence?
    @State private var skipOccurrence: CareOccurrence?
    @State private var showSkipSheet = false

    var body: some View {
        List {
            if let pet = appState.pets.first {
                Section {
                    HStack(spacing: 12) {
                        CareRingView(progress: 0.67, initial: String(pet.name.prefix(1)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(pet.name)
                                .font(.headline)
                            Text("Tue, May 5 - 4 of 6 done")
                                .font(.subheadline)
                                .foregroundStyle(TPColor.muted)
                        }
                        Spacer()
                        Text("67%")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(TPColor.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(TPColor.primarySoft, in: Capsule())
                    }
                }
            }

            Section("Due now") {
                ForEach(appState.todaysOccurrences) { occurrence in
                    if let plan = appState.plan(for: occurrence.planId),
                       let pet = appState.pet(for: occurrence.petId) {
                        CareCardView(
                            pet: pet,
                            plan: plan,
                            occurrence: occurrence,
                            onDone: { appState.markDone(occurrence) },
                            onSnooze: { snoozeOccurrence = occurrence },
                            onSkip: {
                                skipOccurrence = occurrence
                                showSkipSheet = true
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                }
            }

            Section("Later today") {
                Label("Breakfast notes", systemImage: "fork.knife")
                Label("Rio eye drops - 12:30", systemImage: "drop")
                Label("Luna vet visit - 16:00", systemImage: "cross.case")
            }
        }
        .navigationTitle("Today")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .sheet(item: $snoozeOccurrence) { occurrence in
            SnoozeSheet(occurrence: occurrence)
                .presentationDetents([.height(240)])
        }
        .confirmationDialog("Skip with note", isPresented: $showSkipSheet, titleVisibility: .visible) {
            Button("Not eating") {
                if let skipOccurrence {
                    appState.skip(skipOccurrence, reason: "Not eating")
                }
            }
            Button("Vet instructed") {
                if let skipOccurrence {
                    appState.skip(skipOccurrence, reason: "Vet instructed")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct CareCardView: View {
    var pet: Pet
    var plan: CarePlan
    var occurrence: CareOccurrence
    var onDone: () -> Void
    var onSnooze: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(statusText)
                .font(.caption.weight(.bold))
                .foregroundStyle(statusColor)
            Text("\(pet.name)'s \(plan.name)")
                .font(.title3.weight(.bold))
            Text(plan.detail)
                .font(.subheadline)
                .foregroundStyle(TPColor.muted)

            if occurrence.status == .done {
                Text("Completed by \(occurrence.completedBy ?? "Caregiver")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TPColor.primary)
            } else {
                HStack(spacing: 8) {
                    Button("Done", action: onDone)
                        .buttonStyle(PrimaryPillButtonStyle())
                    Button("Snooze", action: onSnooze)
                        .buttonStyle(NeutralPillButtonStyle())
                    Button("Skip", action: onSkip)
                        .buttonStyle(NeutralPillButtonStyle())
                }
            }
        }
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var statusText: String {
        switch occurrence.status {
        case .done: "Done"
        case .skipped: "Skipped"
        case .missed: "Missed"
        default: "Due now"
        }
    }

    private var statusColor: Color {
        occurrence.status == .missed ? TPColor.alert : TPColor.primary
    }

    private var cardBackground: LinearGradient {
        LinearGradient(colors: [TPColor.primarySoft, .white], startPoint: .top, endPoint: .bottom)
    }
}

struct SnoozeSheet: View {
    var occurrence: CareOccurrence

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Snooze reminder")
                .font(.title2.weight(.bold))
            Text("We will remind you again when you have a moment.")
                .foregroundStyle(TPColor.muted)
            HStack {
                Button("10 min") {}
                    .buttonStyle(PrimaryPillButtonStyle())
                Button("30 min") {}
                    .buttonStyle(NeutralPillButtonStyle())
                Button("1 hour") {}
                    .buttonStyle(NeutralPillButtonStyle())
            }
            Spacer()
        }
        .padding()
    }
}

struct PrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(TPColor.primary.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
            .foregroundStyle(.white)
    }
}

struct NeutralPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6).opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
            .foregroundStyle(TPColor.text)
    }
}

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\AddCareView.swift
```swift
import SwiftUI

struct AddCareView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService

    @State private var type: CareType = .medicine
    @State private var name = "Heart med"
    @State private var detail = "1 tablet, after breakfast"
    @State private var dueTime = Date()
    @State private var repeatRule: RepeatRule = .daily

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $type) {
                    ForEach(CareType.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Reminder") {
                Picker("Pet", selection: .constant(appState.pets.first?.id)) {
                    ForEach(appState.pets) { pet in
                        Text(pet.name).tag(Optional(pet.id))
                    }
                }
                TextField("Name", text: $name)
                TextField("Details", text: $detail)
                DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                Picker("Repeat", selection: $repeatRule) {
                    ForEach(RepeatRule.allCases) { rule in
                        Text(rule.rawValue).tag(rule)
                    }
                }
            }

            Section("Notifications") {
                HStack {
                    Text("Notify at care time")
                    Spacer()
                    Text(notifications.authorizationStatus == .authorized ? "On" : "Not enabled")
                        .foregroundStyle(TPColor.muted)
                }
            }

            Button("Save reminder") {
                save()
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Add Care")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
    }

    private func save() {
        guard let pet = appState.pets.first else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: dueTime)
        let plan = CarePlan(
            petId: pet.id,
            type: type,
            name: name,
            detail: detail,
            timeHour: components.hour ?? 8,
            timeMinute: components.minute ?? 0,
            repeatRule: repeatRule
        )
        appState.addCarePlan(plan)
        Task {
            await notifications.schedule(plan: plan, pet: pet)
        }
    }
}

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\SettingsView.swift
```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var store: SubscriptionStore
    @State private var showPaywall = false

    var body: some View {
        List {
            Section("Reminders") {
                HStack {
                    Label("Notifications", systemImage: "bell")
                    Spacer()
                    Text(notificationText)
                        .foregroundStyle(TPColor.muted)
                }
                Button("Test notification") {}
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
                Button("Export data") {}
                Button("Delete account", role: .destructive) {}
                NavigationLink("Medical disclaimer") {
                    Text("Tend Pets helps you record and remember care routines. It does not provide veterinary medical advice. Always follow your veterinarian's instructions.")
                        .padding()
                        .navigationTitle("Disclaimer")
                }
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
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

                if store.products.isEmpty {
                    Text("Subscriptions are loading.")
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
                    }
                }

                Button("Restore Purchase") {
                    Task { await store.refreshEntitlements() }
                }
                .buttonStyle(NeutralPillButtonStyle())

                Text("Trial duration, renewal price, Terms, Privacy, and Restore Purchase must remain visible in the final StoreKit paywall.")
                    .font(.footnote)
                    .foregroundStyle(TPColor.muted)

                Spacer()
            }
            .padding()
            .navigationTitle("Tend Pets Plus")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Services\NotificationService.swift
```swift
import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            refreshAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    func schedule(plan: CarePlan, pet: Pet) async {
        guard plan.notificationEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(pet.name)'s \(plan.name) is due"
        content.body = plan.detail
        content.sound = .default
        content.categoryIdentifier = "CARE_REMINDER"

        var date = DateComponents()
        date.hour = plan.timeHour
        date.minute = plan.timeMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: plan.repeatRule == .daily)
        let request = UNNotificationRequest(identifier: plan.id.uuidString, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    func registerCategories() {
        let done = UNNotificationAction(identifier: "CARE_DONE", title: "Done")
        let snooze = UNNotificationAction(identifier: "CARE_SNOOZE", title: "Snooze")
        let category = UNNotificationCategory(
            identifier: "CARE_REMINDER",
            actions: [done, snooze],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Services\SubscriptionStore.swift
```swift
import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    enum ProductId {
        static let plusMonthly = "tendpets.plus.monthly"
        static let plusYearly = "tendpets.plus.yearly"
        static let familyMonthly = "tendpets.family.monthly"
        static let familyYearly = "tendpets.family.yearly"
    }

    @Published var products: [Product] = []
    @Published var purchasedProductIds: Set<String> = []
    @Published var isLoading = false
    @Published var message: String?

    var hasPlus: Bool {
        !purchasedProductIds.isDisjoint(with: [
            ProductId.plusMonthly,
            ProductId.plusYearly,
            ProductId.familyMonthly,
            ProductId.familyYearly
        ])
    }

    func start() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: [
                ProductId.plusMonthly,
                ProductId.plusYearly,
                ProductId.familyMonthly,
                ProductId.familyYearly
            ])
        } catch {
            message = "Unable to load subscriptions."
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    purchasedProductIds.insert(transaction.productID)
                    await transaction.finish()
                }
            case .userCancelled:
                break
            case .pending:
                message = "Purchase is pending App Store approval."
            @unknown default:
                message = "Purchase could not be completed."
            }
        } catch {
            message = "No charge was made. Please try again."
        }
    }

    func refreshEntitlements() async {
        purchasedProductIds.removeAll()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIds.insert(transaction.productID)
            }
        }
    }
}

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Resources\Info.plist
```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>Tend Pets</string>
  <key>CFBundleShortVersionString</key>
  <string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key>
  <string>$(CURRENT_PROJECT_VERSION)</string>
  <key>UILaunchScreen</key>
  <dict>
    <key>UIColorName</key>
    <string>LaunchBackground</string>
  </dict>
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
  </array>
  <key>NSUserNotificationsUsageDescription</key>
  <string>Tend Pets sends reminders for pet medication, vet visits, vaccines, weight checks, and care routines you create.</string>
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
</dict>
</plist>

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Resources\PrivacyInfo.xcprivacy
```xcprivacy
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>CA92.1</string>
      </array>
    </dict>
  </array>
</dict>
</plist>

```


## File: REDACTED-PATH\generated\pet-med-care-tracker\ios-app\AppStore\submission-checklist.md
```md
# Tend Pets App Store Submission Checklist

## Must Complete On macOS

- Generate Xcode project with XcodeGen
- Set Apple Developer Team ID
- Set bundle identifier if `com.tendpets.app` is unavailable
- Open project in Xcode
- Select a real signing team
- Run on a physical iPhone
- Test notification permission
- Test local reminders
- Test StoreKit sandbox purchases
- Archive with Release configuration
- Upload with Xcode Organizer or Transporter

## App Store Connect

- Create app record: Tend Pets
- Primary category: Medical or Lifestyle
- Secondary category: Utilities
- Add Privacy Policy URL
- Add Support URL
- Configure subscriptions:
  - `tendpets.plus.monthly`
  - `tendpets.plus.yearly`
  - `tendpets.family.monthly`
  - `tendpets.family.yearly`
- Confirm subscription group display names and localized descriptions
- Add 7-day free trial if desired
- Fill app privacy labels based on final data behavior

## Review Safety

Do not claim:

- diagnosis
- dosage recommendation
- treatment advice
- emergency guidance
- disease prevention
- veterinarian replacement

Use:

- reminders
- records
- care logs
- vet visit notes
- follow your veterinarian's instructions

## Current Build Status

This folder is source-ready, but not archive-verified in Xcode because the current environment is Windows.


```
