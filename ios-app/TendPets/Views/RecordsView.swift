import SwiftUI

struct RecordsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSummary = false

    var body: some View {
        List {
            Section("Vet summary") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Prepare clear notes")
                        .font(.headline)
                    Text("Last 30 days, active meds, skipped care, weight trend, vaccine history, and visit notes.")
                        .font(.subheadline)
                        .foregroundStyle(TPColor.muted)
                    Button("Preview PDF") {
                        showSummary = true
                    }
                    .buttonStyle(PrimaryPillButtonStyle())
                    ShareLink(item: vetSummaryShareText) {
                        Label("Share summary text", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(NeutralPillButtonStyle())
                }
                .padding(.vertical, 8)
            }

            Section("Timeline") {
                if appState.records.isEmpty {
                    EmptyStateView(
                        systemImage: "folder.badge.plus",
                        title: "Records will build automatically",
                        message: "Completed, skipped, weight, vaccine, food, and visit notes become a vet-ready history here.",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    ForEach(appState.records.sorted { $0.date > $1.date }) { record in
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.title)
                                    .font(.headline)
                                Text(record.note)
                                    .font(.subheadline)
                                    .foregroundStyle(TPColor.muted)
                                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(TPColor.muted)
                            }
                        } icon: {
                            Image(systemName: record.type.systemImage)
                        }
                    }
                }
            }
        }
        .navigationTitle("Records")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .sheet(isPresented: $showSummary) {
            VetSummaryView()
                .environmentObject(appState)
        }
    }

    private var vetSummaryShareText: String {
        let petName = appState.pets.first?.name ?? "Pet"
        return "\(petName) care summary: active medication, skipped care, weight trend, vaccine history, and visit notes."
    }
}

struct VetSummaryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(primaryPet.name)
                        .font(.title.weight(.bold))
                    Text("\(primaryPet.ageText) - \(primaryPet.weightText)")
                        .foregroundStyle(TPColor.muted)

                    summarySection("Active medication", "Heart med, daily 8:00 AM, after breakfast.")
                    summarySection("Recent skipped care", "May 3: skipped breakfast note. Reason: not eating.")
                    summarySection("Weight trend", "Stable over the last 30 days.")
                    summarySection("Owner notes", "Coughing less this week. Appetite lower in mornings.")
                }
                .padding()
            }
            .navigationTitle("Vet Summary")
            .toolbar {
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var primaryPet: Pet {
        appState.pets.first ?? Pet(name: "Pet", species: .other)
    }

    private var shareText: String {
        "\(primaryPet.name) care summary. Active medication: Heart med daily at 8:00 AM. Recent skipped care: May 3 breakfast note. Weight trend: stable. Owner notes: appetite lower in mornings."
    }

    private func summarySection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(body)
                .foregroundStyle(TPColor.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
            .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private extension RecordType {
    var systemImage: String {
        switch self {
        case .weight: "scalemass"
        case .vaccine: "syringe"
        case .visit: "cross.case"
        case .food: "fork.knife"
        case .note: "note.text"
        case .medicine: "pills"
        }
    }
}
