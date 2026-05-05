import SwiftUI

struct PetsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            if appState.pets.isEmpty {
                Section {
                    EmptyStateView(
                        systemImage: "pawprint",
                        title: "Add your first pet",
                        message: "Tend Pets works for dogs, cats, rabbits, birds, reptiles, fish, and small animals. Start with one profile, then add shared care.",
                        actionTitle: nil,
                        action: nil
                    )
                }
            } else {
                ForEach(appState.pets) { pet in
                    Section {
                        HStack(spacing: 12) {
                            CareRingView(progress: 0.67, initial: String(pet.name.prefix(1)))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pet.name)
                                    .font(.headline)
                                Text("\(pet.ageText) - \(pet.weightText)")
                                    .font(.subheadline)
                                    .foregroundStyle(TPColor.muted)
                            }
                        }
                    }

                    Section("Health overview") {
                        Label("Active medication", systemImage: "pills")
                        Label("Next visit today at 4:00 PM", systemImage: "cross.case")
                        Label("Weight trend stable", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
            }
        }
        .navigationTitle("Pets")
        .toolbar {
            Button {
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add pet")
        }
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
    }
}
