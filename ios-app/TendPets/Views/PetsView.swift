import SwiftUI
import PhotosUI
import UIKit

enum PetsSheet: Identifiable {
    case addPet
    case editPet(Pet)
    case editPlan(CarePlan)
    case quickLog(UUID)
    case paywall

    var id: String {
        switch self {
        case .addPet: "addPet"
        case .editPet(let p): "editPet-\(p.id)"
        case .editPlan(let pl): "editPlan-\(pl.id)"
        case .quickLog(let id): "quickLog-\(id)"
        case .paywall: "paywall"
        }
    }
}

struct PetsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifications: NotificationService
    @State private var sheet: PetsSheet?

    var body: some View {
        List {
            if appState.pets.isEmpty {
                Section {
                    EmptyStateView(
                        systemImage: "pawprint",
                        title: "Add your first pet",
                        message: "Tend Pets works for dogs, cats, rabbits, birds, reptiles, fish, and small animals. Start with one profile, then add shared care.",
                        actionTitle: "Add pet",
                        action: { sheet = .addPet }
                    )
                }
            } else {
                ForEach(appState.pets) { pet in
                    Section {
                        Button {
                            sheet = .editPet(pet)
                        } label: {
                            HStack(spacing: 12) {
                                CareRingView(progress: progress(for: pet), initial: String(pet.name.prefix(1)), photoName: pet.photoName)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(pet.name)
                                            .font(.headline)
                                            .foregroundStyle(TPColor.text)
                                        if pet.isSample {
                                            Text("SAMPLE")
                                                .font(.caption2.weight(.bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(TPColor.primarySoft, in: Capsule())
                                                .foregroundStyle(TPColor.primary)
                                        }
                                    }
                                    Text(pet.isSample
                                         ? "Sample pet — add your own to replace it"
                                         : "\(pet.ageText) — \(pet.weightText)")
                                        .font(.subheadline)
                                        .foregroundStyle(TPColor.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(TPColor.muted)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Edit \(pet.name)")
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                appState.deletePet(pet.id)
                            } label: {
                                Label("Delete pet", systemImage: "trash")
                            }
                        }
                    }

                    Section("Care") {
                        let plans = activePlans(for: pet)
                        if plans.isEmpty {
                            Text("No reminders yet — add one from the Add tab.")
                                .font(.subheadline)
                                .foregroundStyle(TPColor.muted)
                        } else {
                            ForEach(plans) { plan in
                                Button {
                                    sheet = .editPlan(plan)
                                } label: {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(plan.name).foregroundStyle(TPColor.text)
                                            Text(scheduleText(plan))
                                                .font(.caption)
                                                .foregroundStyle(TPColor.muted)
                                            if let supply = plan.supplyRemaining {
                                                Text(plan.isLowSupply
                                                     ? "⚠︎ \(supply) dose\(supply == 1 ? "" : "s") left — refill soon"
                                                     : "\(supply) doses left")
                                                    .font(.caption.weight(plan.isLowSupply ? .bold : .regular))
                                                    .foregroundStyle(plan.isLowSupply ? TPColor.alert : TPColor.muted)
                                            }
                                        }
                                    } icon: {
                                        Image(systemName: plan.type.careIcon)
                                            .foregroundStyle(plan.type.tint)
                                    }
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        appState.deleteCarePlan(plan.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        Button {
                            sheet = .quickLog(pet.id)
                        } label: {
                            Label("Log weight or symptom", systemImage: "plus.circle")
                                .foregroundStyle(TPColor.primary)
                        }

                        if let weightSummary = weightSummary(for: pet) {
                            Label(weightSummary, systemImage: "scalemass")
                                .font(.subheadline)
                                .foregroundStyle(TPColor.muted)
                        }
                    }
                }
            }
        }
        .navigationTitle("Pets")
        .toolbar {
            Button {
                if appState.canAddPet(hasPlus: store.hasPlus) {
                    sheet = .addPet
                } else {
                    sheet = .paywall
                }
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add pet")
        }
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .onChange(of: appState.requestAddPet) { _, want in
            if want {
                sheet = .addPet
                appState.requestAddPet = false
            }
        }
        .onAppear {
            if appState.requestAddPet {
                sheet = .addPet
                appState.requestAddPet = false
            }
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .addPet:
                AddPetSheet().environmentObject(appState)
            case .editPet(let pet):
                AddPetSheet(editingPet: pet).environmentObject(appState)
            case .editPlan(let plan):
                CarePlanEditSheet(plan: plan)
                    .environmentObject(appState)
                    .environmentObject(notifications)
                    .environmentObject(store)
            case .quickLog(let petId):
                QuickLogSheet(initialPetId: petId).environmentObject(appState)
            case .paywall:
                PaywallView().environmentObject(store)
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Only nag once the user actually has a real pet at the free limit —
            // a lone sample pet must not trigger the upgrade banner.
            if !store.hasPlus && appState.realPetCount >= AppState.freeMaxPets {
                HStack {
                    Image(systemName: "lock")
                    Text("Free plan supports 1 pet. Upgrade for unlimited pets.")
                        .font(.footnote)
                    Spacer()
                    Button("Upgrade") { sheet = .paywall }
                        .font(.footnote.weight(.semibold))
                }
                .padding(12)
                .background(TPColor.primarySoft)
            }
        }
    }

    private func scheduleText(_ plan: CarePlan) -> String {
        let time = String(format: "%02d:%02d", plan.timeHour, plan.timeMinute)
        switch plan.repeatRule {
        case .daily:
            return "Daily at \(time)"
        case .onDate:
            if let d = plan.specificDate {
                return "\(d.formatted(date: .abbreviated, time: .omitted)) at \(time)"
            }
            return "At \(time)"
        }
    }

    // MARK: - Computed values per pet (no hardcoded fake data)

    private func progress(for pet: Pet) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaysForPet = appState.occurrences.filter {
            $0.petId == pet.id && calendar.isDate($0.dueAt, inSameDayAs: today)
        }
        guard !todaysForPet.isEmpty else { return 0 }
        let done = todaysForPet.filter { $0.status == .done }.count
        return Double(done) / Double(todaysForPet.count)
    }

    private func activePlans(for pet: Pet) -> [CarePlan] {
        appState.carePlans.filter { $0.petId == pet.id && $0.active }
    }

    private func nextVisitText(for pet: Pet) -> String? {
        let upcomingVisits = appState.occurrences
            .filter { $0.petId == pet.id && $0.status != .done && $0.status != .skipped }
            .compactMap { occ -> (CareOccurrence, CarePlan)? in
                guard let plan = appState.plan(for: occ.planId), plan.type == .visit else { return nil }
                return (occ, plan)
            }
            .sorted { $0.0.dueAt < $1.0.dueAt }

        guard let next = upcomingVisits.first else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Next visit \(formatter.string(from: next.0.dueAt))"
    }

    private func weightSummary(for pet: Pet) -> String? {
        let weightRecords = appState.records
            .filter { $0.petId == pet.id && $0.type == .weight }
            .sorted { $0.date > $1.date }
        guard let latest = weightRecords.first else {
            if let weight = pet.weightValue {
                return "Weight \(weight.formatted(.number.precision(.fractionLength(0...1)))) \(pet.weightUnit.rawValue)"
            }
            return nil
        }
        return "Last weight \(latest.value ?? "—") on \(latest.date.formatted(date: .abbreviated, time: .omitted))"
    }
}

struct AddPetSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let editingPet: Pet?

    @State private var name: String
    @State private var species: Species
    @State private var birthYear: Int
    @State private var weightValue: String
    @State private var weightUnit: WeightUnit
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var existingPhotoName: String?
    @State private var validationMessage: String?

    init(editingPet: Pet? = nil) {
        self.editingPet = editingPet
        let thisYear = Calendar(identifier: .gregorian).component(.year, from: Date())
        _name = State(initialValue: editingPet?.name ?? "")
        _species = State(initialValue: editingPet?.species ?? .cat)
        _birthYear = State(initialValue: editingPet?.birthYear ?? (thisYear - 3))
        _weightValue = State(initialValue: editingPet?.weightValue.map {
            $0.formatted(.number.precision(.fractionLength(0...1)))
        } ?? "")
        _weightUnit = State(initialValue: editingPet?.weightUnit ?? AddPetSheet.defaultWeightUnit)
        _existingPhotoName = State(initialValue: editingPet?.photoName)
    }

    /// Default unit based on the user's measurement system. US users default to lb,
    /// metric users default to kg. Apple Locale.measurementSystem is iOS 16+.
    private static var defaultWeightUnit: WeightUnit {
        if #available(iOS 16.0, *) {
            return Locale.current.measurementSystem == .us ? .lb : .kg
        }
        return .kg
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            if let photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else if let existing = PetImageStore.image(named: existingPhotoName) {
                                Image(uiImage: existing)
                                    .resizable().scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(TPColor.primarySoft)
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Image(systemName: "pawprint.fill")
                                            .foregroundStyle(TPColor.primary)
                                    )
                            }
                        }
                        PhotosPicker(
                            selection: $photoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text((photoData == nil && existingPhotoName == nil) ? "Add photo" : "Change photo")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TPColor.primary)
                        }
                        if photoData != nil || existingPhotoName != nil {
                            Spacer()
                            Button("Remove") {
                                photoData = nil
                                photoItem = nil
                                existingPhotoName = nil
                            }
                            .font(.subheadline)
                            .foregroundStyle(TPColor.muted)
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("About this pet") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .accessibilityLabel("Pet name")
                    Picker("Species", selection: $species) {
                        ForEach(Species.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    Stepper(value: $birthYear, in: 1990...Calendar(identifier: .gregorian).component(.year, from: Date())) {
                        Text("Birth year: \(String(birthYear))")
                    }
                }

                Section("Weight (optional)") {
                    HStack {
                        TextField("Weight", text: $weightValue)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Weight value")
                        Picker("Unit", selection: $weightUnit) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(TPColor.alert)
                    }
                }

                Button(editingPet == nil ? "Save pet" : "Save changes") {
                    save()
                }
                .disabled(!canSave)
                .buttonStyle(PrimaryPillButtonStyle())
                .listRowBackground(Color.clear)
            }
            .navigationTitle(editingPet == nil ? "New pet" : "Edit pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Reasonable upper bound for a pet weight in kg (or equivalent). Largest dog
    /// breeds top out around 100 kg; we cap at 500 kg to allow horses or unusual
    /// exotic pets while rejecting clearly invalid input like 999999.
    private static let maxWeightInKg: Double = 500

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Pet name is required."
            return
        }

        // Cap name length so very long input does not break notification titles
        // or list layouts.
        let cappedName = String(trimmedName.prefix(80))

        let trimmedWeight = weightValue.trimmingCharacters(in: .whitespacesAndNewlines)
        var parsedWeight: Double? = nil
        if !trimmedWeight.isEmpty {
            guard let value = Double(trimmedWeight) else {
                validationMessage = "Weight must be a number."
                return
            }
            guard value > 0 else {
                validationMessage = "Weight must be greater than zero."
                return
            }
            // Convert to kg-equivalent for the sanity cap so a US user typing
            // "1100" (lb of a giant horse) is treated as ~500 kg, still allowed.
            let kgEquivalent: Double = {
                switch weightUnit {
                case .kg: return value
                case .lb: return value * 0.4536
                case .g: return value / 1000
                }
            }()
            guard kgEquivalent <= Self.maxWeightInKg else {
                validationMessage = "Weight looks too large. Please check the value and unit."
                return
            }
            parsedWeight = value
        }

        // If the user picked a new photo, persist it; otherwise keep whatever
        // photo the pet already had (existingPhotoName is cleared by "Remove").
        let savedPhotoName = photoData.flatMap { PetImageStore.save($0) } ?? existingPhotoName

        if let editingPet {
            var updated = editingPet
            updated.name = cappedName
            updated.species = species
            updated.birthYear = birthYear
            updated.weightValue = parsedWeight
            updated.weightUnit = weightUnit
            updated.photoName = savedPhotoName
            // Editing the sample pet adopts it as a real pet.
            updated.isSample = false
            appState.updatePet(updated)
        } else {
            let pet = Pet(
                name: cappedName,
                species: species,
                birthYear: birthYear,
                weightValue: parsedWeight,
                weightUnit: weightUnit,
                photoName: savedPhotoName
            )
            appState.addPet(pet)
        }
        dismiss()
    }
}
