import SwiftUI

struct AddCareView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService

    @State private var type: CareType = .medicine
    @State private var name = "Heart med"
    @State private var detail = "1 tablet, after breakfast"
    @State private var dueTime = Date()
    @State private var repeatRule: RepeatRule = .daily
    @State private var selectedPetId: UUID?
    @State private var validationMessage: String?

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
                DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                    .accessibilityHint("Choose the time Tend Pets should remind you.")
                Picker("Repeat", selection: $repeatRule) {
                    ForEach(RepeatRule.allCases) { rule in
                        Text(rule.rawValue).tag(rule)
                    }
                }
            }

            Section("Notifications") {
                HStack {
                    Text(config.notificationTitle)
                    Spacer()
                    Text(notifications.authorizationStatus == .authorized ? "On" : "Not enabled")
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
    }

    private var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return selectedPetId != nil && hasName
    }

    private func save() {
        let config = AddCareConfig(type: type)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = config.nameRequiredMessage
            return
        }

        guard !config.detailRequired || !trimmedDetail.isEmpty else {
            validationMessage = config.detailRequiredMessage
            return
        }

        guard
            let selectedPetId,
            let pet = appState.pet(for: selectedPetId)
        else {
            validationMessage = "Choose a pet before saving."
            return
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: dueTime)
        let plan = CarePlan(
            petId: pet.id,
            type: type,
            name: trimmedName,
            detail: trimmedDetail.isEmpty ? config.defaultDetail : trimmedDetail,
            timeHour: components.hour ?? 8,
            timeMinute: components.minute ?? 0,
            repeatRule: repeatRule
        )
        appState.addCarePlan(plan)
        validationMessage = nil
        Task { @MainActor in
            var canScheduleNotification = notifications.isAuthorized
            if notifications.authorizationStatus == .notDetermined {
                canScheduleNotification = await notifications.requestAuthorization()
            }

            if canScheduleNotification {
                await notifications.schedule(plan: plan, pet: pet)
            } else {
                validationMessage = "Reminder saved. Notifications are off for this device."
            }
        }
    }
}

private struct AddCareConfig {
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
