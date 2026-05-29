import SwiftUI

struct AddCareView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var store: SubscriptionStore
    @State private var showPaywall = false

    @State private var type: CareType = .medicine
    @State private var name = ""
    @State private var detail = ""
    @State private var dueTime: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var specificDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var repeatRule: RepeatRule = .daily
    @State private var selectedPetId: UUID?
    @State private var trackSupply = false
    @State private var supplyCount = 30
    @State private var validationMessage: String?

    private var requiresSpecificDate: Bool {
        // Vaccine and Visit reminders are typically future-dated single events,
        // not daily recurrences. Force date picker for these types.
        type == .vaccine || type == .visit
    }

    var body: some View {
        let config = AddCareConfig(type: type)

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
                Picker("Pet", selection: $selectedPetId) {
                    ForEach(appState.pets) { pet in
                        Text(pet.name).tag(Optional(pet.id))
                    }
                }
                TextField(config.namePlaceholder, text: $name)
                    .textContentType(.none)
                    .accessibilityLabel(config.nameAccessibilityLabel)
                TextField(config.detailPlaceholder, text: $detail)
                    .textContentType(.none)
                    .accessibilityLabel(config.detailAccessibilityLabel)
                if requiresSpecificDate {
                    DatePicker(
                        "Date",
                        selection: $specificDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .accessibilityHint("Choose the calendar date for this reminder.")
                }
                DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                    .accessibilityHint("Choose the time Tend Pets should remind you.")
                if !requiresSpecificDate {
                    Picker("Repeat", selection: $repeatRule) {
                        ForEach(RepeatRule.available(hasPlus: store.hasPlus)) { rule in
                            Text(rule.rawValue).tag(rule)
                        }
                    }
                    if !store.hasPlus {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("Twice / 3× daily schedules", systemImage: "clock.arrow.2.circlepath")
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
            .onChange(of: type) { _, newType in
                // Vaccine/Visit are inherently single-date events; medicine/food/weight
                // default to daily. Sync repeatRule to keep the UI honest.
                if newType == .vaccine || newType == .visit {
                    repeatRule = .onDate
                } else {
                    repeatRule = .daily
                }
            }

            if type == .medicine {
                Section("Refills") {
                    if store.hasPlus {
                        Toggle("Track supply & low-stock alerts", isOn: $trackSupply)
                        if trackSupply {
                            Stepper("Doses in supply: \(supplyCount)", value: $supplyCount, in: 1...3650)
                            Text("Each time you mark this med done, supply drops by one. You'll see a refill warning at \(CarePlan.lowSupplyThreshold) or fewer left.")
                                .font(.footnote)
                                .foregroundStyle(TPColor.muted)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("Track supply & refill alerts", systemImage: "pills.circle")
                                Spacer()
                                Text("Plus")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(TPColor.primarySoft, in: Capsule())
                                    .foregroundStyle(TPColor.primary)
                            }
                        }
                    }
                }
            }

            Section("Notifications") {
                HStack {
                    Text(config.notificationTitle)
                    Spacer()
                    Text(notifications.isAuthorized ? "On" : "Not enabled")
                        .foregroundStyle(TPColor.muted)
                }
                Text(config.notificationDetail)
                    .font(.footnote)
                    .foregroundStyle(TPColor.muted)
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(TPColor.alert)
                }
            }

            Button(config.saveTitle) {
                save()
            }
            .disabled(!canSave)
            .buttonStyle(PrimaryPillButtonStyle())
            .listRowBackground(Color.clear)
            .accessibilityHint("Saves this care item and schedules a notification if allowed.")
        }
        .navigationTitle("Add Care")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .onAppear {
            selectedPetId = selectedPetId ?? appState.pets.first?.id
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
    }

    private var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return selectedPetId != nil && hasName
    }

    private func save() {
        let config = AddCareConfig(type: type)
        // Cap input length so very long input does not break notification titles
        // (UN content title soft-limit ~ 78 chars on lock screen) or list rows.
        let trimmedName = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        let trimmedDetail = String(detail.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))

        guard !trimmedName.isEmpty else {
            validationMessage = config.nameRequiredMessage
            return
        }

        guard !config.detailRequired || !trimmedDetail.isEmpty else {
            validationMessage = config.detailRequiredMessage
            return
        }

        guard
            let petId = selectedPetId,
            let pet = appState.pet(for: petId)
        else {
            validationMessage = "Choose a pet before saving."
            return
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: dueTime)
        var plan = CarePlan(
            petId: pet.id,
            type: type,
            name: trimmedName,
            detail: trimmedDetail.isEmpty ? config.defaultDetail : trimmedDetail,
            timeHour: components.hour ?? 8,
            timeMinute: components.minute ?? 0,
            repeatRule: repeatRule,
            specificDate: requiresSpecificDate ? specificDate : nil
        )
        if type == .medicine && trackSupply && store.hasPlus {
            plan.supplyRemaining = supplyCount
        }
        appState.addCarePlan(plan)
        validationMessage = nil

        // Reset the form so the next reminder starts empty instead of
        // re-using the previous entry's text. type and selectedPetId are
        // @State and persist naturally — only the text fields need clearing.
        name = ""
        detail = ""

        Task { @MainActor in
            var canScheduleNotification = notifications.isAuthorized
            if notifications.authorizationStatus == .notDetermined {
                canScheduleNotification = await notifications.requestAuthorization()
            }

            if canScheduleNotification {
                await notifications.schedule(plan: plan, pet: pet)
                validationMessage = "Reminder saved."
            } else {
                validationMessage = "Reminder saved. Notifications are off for this device."
            }
        }
    }
}

struct AddCareConfig {
    var type: CareType

    var namePlaceholder: String {
        switch type {
        case .medicine: "Medication name"
        case .food: "Meal or food note"
        case .weight: "Weight check"
        case .visit: "Visit reason"
        case .vaccine: "Vaccine name"
        }
    }

    var detailPlaceholder: String {
        switch type {
        case .medicine: "Dose and instructions"
        case .food: "Amount or appetite note"
        case .weight: "Weight value and unit"
        case .visit: "Clinic, doctor, or prep note"
        case .vaccine: "Lot, due date, or certificate note"
        }
    }

    var nameAccessibilityLabel: String {
        "\(type.rawValue) name"
    }

    var detailAccessibilityLabel: String {
        switch type {
        case .medicine: "Dose and medication instructions"
        case .food: "Food amount or appetite note"
        case .weight: "Weight value and unit"
        case .visit: "Visit clinic or preparation note"
        case .vaccine: "Vaccine record details"
        }
    }

    var detailRequired: Bool {
        type == .medicine
    }

    var nameRequiredMessage: String {
        switch type {
        case .medicine: "Medication name is required."
        case .food: "Meal or food note name is required."
        case .weight: "Weight record name is required."
        case .visit: "Visit reason is required."
        case .vaccine: "Vaccine name is required."
        }
    }

    var detailRequiredMessage: String {
        "Enter the dose or instructions from your vet label."
    }

    var defaultDetail: String {
        switch type {
        case .medicine: "Medication reminder"
        case .food: "Food note"
        case .weight: "Weight check"
        case .visit: "Vet visit"
        case .vaccine: "Vaccine record"
        }
    }

    var notificationTitle: String {
        switch type {
        case .medicine: "Notify at medication time"
        case .food: "Notify at meal time"
        case .weight: "Notify to weigh"
        case .visit: "Notify before visit"
        case .vaccine: "Notify before vaccine due date"
        }
    }

    var notificationDetail: String {
        switch type {
        case .medicine: "The notification supports Done and Snooze actions."
        case .food: "Useful for appetite and diet changes."
        case .weight: "Keeps trends ready for vet visits."
        case .visit: "Prepare questions, meds, and recent records."
        case .vaccine: "Keep vaccine timing visible before it expires."
        }
    }

    var saveTitle: String {
        switch type {
        case .medicine: "Save medication"
        case .food: "Save food reminder"
        case .weight: "Save weight reminder"
        case .visit: "Save visit"
        case .vaccine: "Save vaccine"
        }
    }
}
