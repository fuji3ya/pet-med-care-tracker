import SwiftUI
import PhotosUI
import UIKit

struct PetsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: SubscriptionStore
    @State private var showAddPet = false
    @State private var showPaywall = false

    var body: some View {
        List {
            if appState.pets.isEmpty {
                Section {
                    EmptyStateView(
                        systemImage: "pawprint",
                        title: "Add your first pet",
                        message: "Tend Pets works for dogs, cats, rabbits, birds, reptiles, fish, and small animals. Start with one profile, then add shared care.",
                        actionTitle: "Add pet",
                        action: { showAddPet = true }
                    )
                }
            } else {
                ForEach(appState.pets) { pet in
                    Section {
                        HStack(spacing: 12) {
                            CareRingView(progress: progress(for: pet), initial: String(pet.name.prefix(1)), photoName: pet.photoName)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pet.name)
                                    .font(.headline)
                                Text("\(pet.ageText) — \(pet.weightText)")
                                    .font(.subheadline)
                                    .foregroundStyle(TPColor.muted)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                appState.deletePet(pet.id)
                            } label: {
                                Label("Delete pet", systemImage: "trash")
                            }
                        }
                    }

                    let plans = activePlans(for: pet)
                    let nextVisit = nextVisitText(for: pet)
                    let weightSummary = weightSummary(for: pet)

                    if !plans.isEmpty || nextVisit != nil || weightSummary != nil {
                        Section("Care overview") {
                            if !plans.isEmpty {
                                Label("\(plans.count) active reminder\(plans.count == 1 ? "" : "s")", systemImage: "bell")
                            }
                            if let nextVisit {
                                Label(nextVisit, systemImage: "cross.case")
                            }
                            if let weightSummary {
                                Label(weightSummary, systemImage: "scalemass")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Pets")
        .toolbar {
            Button {
                if appState.canAddPet(hasPlus: store.hasPlus) {
                    showAddPet = true
                } else {
                    showPaywall = true
                }
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add pet")
        }
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .sheet(isPresented: $showAddPet) {
            AddPetSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
        .safeAreaInset(edge: .bottom) {
            if !store.hasPlus && appState.pets.count >= AppState.freeMaxPets {
                HStack {
                    Image(systemName: "lock")
                    Text("Free plan supports 1 pet. Upgrade for unlimited pets.")
                        .font(.footnote)
                    Spacer()
                    Button("Upgrade") { showPaywall = true }
                        .font(.footnote.weight(.semibold))
                }
                .padding(12)
                .background(TPColor.primarySoft)
            }
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

    @State private var name = ""
    @State private var species: Species = .cat
    @State private var birthYear = Calendar(identifier: .gregorian).component(.year, from: Date()) - 3
    @State private var weightValue = ""
    @State private var weightUnit: WeightUnit = AddPetSheet.defaultWeightUnit
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var validationMessage: String?

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
                                    .resizable()
                                    .scaledToFill()
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
                            Text(photoData == nil ? "Add photo" : "Change photo")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TPColor.primary)
                        }
                        if photoData != nil {
                            Spacer()
                            Button("Remove") {
                                photoData = nil
                                photoItem = nil
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

                Button("Save pet") {
                    save()
                }
                .disabled(!canSave)
                .buttonStyle(PrimaryPillButtonStyle())
                .listRowBackground(Color.clear)
            }
            .navigationTitle("New pet")
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

        let savedPhotoName = photoData.flatMap { PetImageStore.save($0) }

        let pet = Pet(
            name: cappedName,
            species: species,
            birthYear: birthYear,
            weightValue: parsedWeight,
            weightUnit: weightUnit,
            photoName: savedPhotoName
        )
        appState.addPet(pet)
        dismiss()
    }
}
