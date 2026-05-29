import SwiftUI

/// Edit an existing reminder (care plan). Reschedules the local notification and
/// can delete the reminder. Reuses AddCareConfig for consistent field labels.
struct CarePlanEditSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    let plan: CarePlan

    @State private var type: CareType
    @State private var name: String
    @State private var detail: String
    @State private var dueTime: Date
    @State private var specificDate: Date
    @State private var repeatRule: RepeatRule
    @State private var trackSupply: Bool
    @State private var supplyCount: Int
    @State private var showPaywall = false
    @State private var validationMessage: String?

    init(plan: CarePlan) {
        self.plan = plan
        _type = State(initialValue: plan.type)
        _name = State(initialValue: plan.name)
        _detail = State(initialValue: plan.detail)
        var comps = DateComponents()
        comps.hour = plan.timeHour
        comps.minute = plan.timeMinute
        _dueTime = State(initialValue: Calendar.current.date(from: comps) ?? Date())
        _specificDate = State(initialValue: plan.specificDate ?? Date())
        _repeatRule = State(initialValue: plan.repeatRule)
        _trackSupply = State(initialValue: plan.supplyRemaining != nil)
        _supplyCount = State(initialValue: plan.supplyRemaining ?? 30)
    }

    private var requiresSpecificDate: Bool { type == .vaccine || type == .visit }

    var body: some View {
        NavigationStack {
            Form {
                let config = AddCareConfig(type: type)
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(CareType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Reminder") {
                    TextField(config.namePlaceholder, text: $name)
                    TextField(config.detailPlaceholder, text: $detail)
                    if requiresSpecificDate {
                        DatePicker("Date", selection: $specificDate, in: Date()..., displayedComponents: .date)
                    }
                    DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                    if !requiresSpecificDate {
                        Picker("Repeat", selection: $repeatRule) {
                            ForEach(RepeatRule.available(hasPlus: store.hasPlus)) { Text($0.rawValue).tag($0) }
                        }
                    }
                }
                .onChange(of: type) { _, newType in
                    repeatRule = (newType == .vaccine || newType == .visit) ? .onDate : .daily
                }

                if type == .medicine {
                    Section("Refills") {
                        if store.hasPlus {
                            Toggle("Track supply & low-stock alerts", isOn: $trackSupply)
                            if trackSupply {
                                Stepper("Doses in supply: \(supplyCount)", value: $supplyCount, in: 1...3650)
                                Text("Refilled? Set this back up. Warning shows at \(CarePlan.lowSupplyThreshold) or fewer.")
                                    .font(.footnote).foregroundStyle(TPColor.muted)
                            }
                        } else {
                            Button { showPaywall = true } label: {
                                HStack {
                                    Label("Track supply & refill alerts", systemImage: "pills.circle")
                                    Spacer()
                                    Text("Plus").font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(TPColor.primarySoft, in: Capsule())
                                        .foregroundStyle(TPColor.primary)
                                }
                            }
                        }
                    }
                }

                if let validationMessage {
                    Section { Text(validationMessage).font(.footnote).foregroundStyle(TPColor.alert) }
                }

                Button("Save changes") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(PrimaryPillButtonStyle())
                    .listRowBackground(Color.clear)

                Section {
                    Button("Delete reminder", role: .destructive) {
                        appState.deleteCarePlan(plan.id)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(store)
            }
        }
    }

    private func save() {
        let trimmedName = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        guard !trimmedName.isEmpty else { validationMessage = "Name is required."; return }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: dueTime)
        var updated = plan
        updated.type = type
        updated.name = trimmedName
        updated.detail = String(detail.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))
        updated.timeHour = comps.hour ?? 8
        updated.timeMinute = comps.minute ?? 0
        updated.repeatRule = repeatRule
        updated.specificDate = requiresSpecificDate ? specificDate : nil
        updated.supplyRemaining = (type == .medicine && trackSupply && store.hasPlus) ? supplyCount : nil

        appState.updateCarePlan(updated)

        if let pet = appState.pet(for: updated.petId) {
            Task { @MainActor in
                if notifications.isAuthorized {
                    await notifications.schedule(plan: updated, pet: pet)
                }
            }
        }
        dismiss()
    }
}
