import SwiftUI
import PhotosUI
import UIKit

/// Ad-hoc logging: record a one-off weight, symptom, or note without first
/// creating a reminder. This is what makes weight tracking real — each entry is
/// a fresh measured value with its own date.
struct QuickLogSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    enum LogKind: String, CaseIterable, Identifiable {
        case weight = "Weight"
        case symptom = "Symptom"
        case note = "Note"
        var id: String { rawValue }
    }

    var initialPetId: UUID?

    @State private var kind: LogKind = .weight
    @State private var petId: UUID?
    @State private var date = Date()

    // Weight
    @State private var weightValue = ""
    @State private var weightUnit: WeightUnit = .kg

    // Symptom
    @State private var symptomName = ""
    @State private var severity: SymptomSeverity = .mild

    // Note / shared
    @State private var noteText = ""
    // Attachment (Plus "vet binder")
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showPaywall = false
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("What to log", selection: $kind) {
                        ForEach(LogKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Picker("Pet", selection: $petId) {
                        ForEach(appState.pets) { pet in
                            Text(pet.name).tag(Optional(pet.id))
                        }
                    }
                    DatePicker("When", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                }

                switch kind {
                case .weight:
                    Section("Weight") {
                        HStack {
                            TextField("Weight", text: $weightValue)
                                .keyboardType(.decimalPad)
                                .accessibilityLabel("Weight value")
                            Picker("Unit", selection: $weightUnit) {
                                ForEach(WeightUnit.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                    }
                case .symptom:
                    Section("Symptom") {
                        TextField("What did you notice? (e.g. vomiting)", text: $symptomName)
                        Picker("Severity", selection: $severity) {
                            ForEach(SymptomSeverity.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        TextField("Details (optional)", text: $noteText, axis: .vertical)
                            .lineLimit(1...4)
                    }
                case .note:
                    Section("Note") {
                        TextField("Note (e.g. ate well, more energy)", text: $noteText, axis: .vertical)
                            .lineLimit(1...5)
                    }
                }

                if kind != .weight {
                    Section("Attachment") {
                        if store.hasPlus {
                            if let photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFit()
                                    .frame(maxHeight: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            HStack {
                                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                                    Label(photoData == nil ? "Attach photo or document" : "Change attachment", systemImage: "paperclip")
                                        .foregroundStyle(TPColor.primary)
                                }
                                if photoData != nil {
                                    Spacer()
                                    Button("Remove") { photoData = nil; photoItem = nil }
                                        .foregroundStyle(TPColor.muted)
                                }
                            }
                        } else {
                            Button { showPaywall = true } label: {
                                HStack {
                                    Label("Attach photo / vaccine cert (vet binder)", systemImage: "paperclip")
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
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(TPColor.alert)
                    }
                }

                Button("Save to history") { save() }
                    .disabled(!canSave)
                    .buttonStyle(PrimaryPillButtonStyle())
                    .listRowBackground(Color.clear)
            }
            .navigationTitle("Quick log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                petId = petId ?? initialPetId ?? appState.pets.first?.id
                weightUnit = appState.pets.first(where: { $0.id == petId })?.weightUnit ?? .kg
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(store)
            }
        }
    }

    private var canSave: Bool {
        guard petId != nil else { return false }
        switch kind {
        case .weight: return Double(weightValue.trimmingCharacters(in: .whitespaces)) != nil
        case .symptom: return !symptomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .note: return !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func save() {
        guard let petId else { return }
        // Persist any attached photo/document (Plus only).
        let attachment: String? = (store.hasPlus ? photoData.flatMap { PetImageStore.save($0) } : nil)
        switch kind {
        case .weight:
            guard let v = Double(weightValue.trimmingCharacters(in: .whitespaces)), v > 0 else {
                validationMessage = "Enter a weight greater than zero."
                return
            }
            appState.logWeight(petId: petId, value: v, unit: weightUnit, date: date)
        case .symptom:
            let name = String(symptomName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
            appState.logSymptom(petId: petId, name: name, severity: severity,
                                note: String(noteText.prefix(300)), date: date, attachmentName: attachment)
        case .note:
            let text = String(noteText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(300))
            appState.logRecord(petId: petId, type: .note, title: "Note", value: nil, note: text, date: date, attachmentName: attachment)
        }
        dismiss()
    }
}
