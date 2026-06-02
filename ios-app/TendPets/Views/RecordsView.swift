import SwiftUI
import UIKit

struct RecordsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: SubscriptionStore
    @State private var showSummary = false
    @State private var showPaywall = false

    var body: some View {
        let visibleRecords = appState.recordsVisibleToUser(hasPlus: store.hasPlus)
        let totalRecords = appState.records.count

        List {
            Section("Vet summary") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Prepare clear notes")
                            .font(.headline)
                        if !store.hasPlus {
                            Text("Plus")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(TPColor.primarySoft, in: Capsule())
                                .foregroundStyle(TPColor.primary)
                        }
                    }
                    Text(store.hasPlus
                         ? "Last 30 days of active meds, skipped care, weight history, vaccine records, and visit notes — built from this device's records."
                         : "Tend Pets Plus builds a vet-ready summary from your records: active meds, skipped care, weight trend, vaccine and visit history.")
                        .font(.subheadline)
                        .foregroundStyle(TPColor.muted)
                    if store.hasPlus {
                        Button("Open summary") {
                            showSummary = true
                        }
                        .buttonStyle(PrimaryPillButtonStyle())
                        ShareLink(item: VetSummary(appState: appState).shareText) {
                            Label("Share summary text", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(NeutralPillButtonStyle())
                    } else {
                        Button("Unlock with Plus") {
                            showPaywall = true
                        }
                        .buttonStyle(PrimaryPillButtonStyle())
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Timeline") {
                if visibleRecords.isEmpty && totalRecords == 0 {
                    EmptyStateView(
                        systemImage: "folder.badge.plus",
                        title: "Records will build automatically",
                        message: "Completed, skipped, weight, vaccine, food, and visit notes become a vet-ready history here.",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    ForEach(visibleRecords.sorted { $0.date > $1.date }) { record in
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
                                if let img = PetImageStore.image(named: record.attachmentName) {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: 140)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .padding(.top, 4)
                                }
                            }
                        } icon: {
                            Image(systemName: record.attachmentName != nil ? "paperclip" : record.type.systemImage)
                        }
                    }
                }
            }

            Section {
                NavigationLink {
                    MedicalSafetyView()
                } label: {
                    Label("Medical disclaimer & sources", systemImage: "cross.case")
                }
            } footer: {
                Text("Tend Pets records the care you and your vet decide on — it does not give medical advice. Tap above for the disclaimer and citations to trusted veterinary sources.")
            }
        }
        .navigationTitle("Records")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .sheet(isPresented: $showSummary) {
            VetSummaryView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
    }
}

// MARK: - VetSummary — derives summary text from actual AppState data.
// @MainActor because it reads @MainActor-isolated AppState properties; it is
// always constructed and consumed within View bodies (also MainActor).

@MainActor
struct VetSummary {
    let appState: AppState

    var primaryPet: Pet? {
        appState.pets.first
    }

    var activeMedicationLines: [String] {
        appState.carePlans
            .filter { $0.type == .medicine && $0.active }
            .map { plan in
                let time = String(format: "%02d:%02d", plan.timeHour, plan.timeMinute)
                let detail = plan.detail.isEmpty ? "no detail" : plan.detail
                return "• \(plan.name) — \(plan.repeatRule.rawValue.lowercased()) at \(time) (\(detail))"
            }
    }

    var recentSkippedLines: [String] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        return appState.records
            .filter { $0.date >= cutoff && $0.title.contains("skipped") }
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { record in
                "• \(record.date.formatted(date: .abbreviated, time: .omitted)): \(record.title) (\(record.value ?? "no reason"))"
            }
    }

    var weightTrendText: String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        let weights = appState.records
            .filter { $0.type == .weight && $0.date >= cutoff }
            .sorted { $0.date < $1.date }
        guard !weights.isEmpty else {
            if let weight = primaryPet?.weightValue, let pet = primaryPet {
                return "Current: \(weight.formatted(.number.precision(.fractionLength(0...1)))) \(pet.weightUnit.rawValue). No weight check-ins recorded in the last 30 days."
            }
            return "No weight history recorded."
        }
        return weights
            .map { "• \($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.value ?? "—")" }
            .joined(separator: "\n")
    }

    var vaccineHistoryLines: [String] {
        appState.records
            .filter { $0.type == .vaccine }
            .sorted { $0.date > $1.date }
            .prefix(10)
            .map { "• \($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.title) (\($0.value ?? "no lot"))" }
    }

    var recentVisitLines: [String] {
        appState.records
            .filter { $0.type == .visit }
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { "• \($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.title) — \($0.note)" }
    }

    var recentSymptomLines: [String] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        return appState.records
            .filter { $0.type == .symptom && $0.date >= cutoff }
            .sorted { $0.date > $1.date }
            .prefix(10)
            .map { "• \($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.title) (\($0.value ?? "—"))\($0.note.isEmpty ? "" : " — \($0.note)")" }
    }

    /// Numeric weight points for the chart (oldest first).
    var weightPoints: [(date: Date, value: Double)] {
        guard let pet = primaryPet else { return [] }
        return appState.weightSeries(for: pet.id)
    }

    var shareText: String {
        let petName = primaryPet?.name ?? "Pet"
        var lines: [String] = ["\(petName) — care summary (last 30 days)", ""]

        lines.append("Active medication:")
        lines.append(activeMedicationLines.isEmpty ? "• None recorded" : activeMedicationLines.joined(separator: "\n"))
        lines.append("")

        lines.append("Recent skipped care:")
        lines.append(recentSkippedLines.isEmpty ? "• None" : recentSkippedLines.joined(separator: "\n"))
        lines.append("")

        lines.append("Weight history:")
        lines.append(weightTrendText)
        lines.append("")

        lines.append("Vaccine history:")
        lines.append(vaccineHistoryLines.isEmpty ? "• None recorded" : vaccineHistoryLines.joined(separator: "\n"))
        lines.append("")

        lines.append("Recent visits:")
        lines.append(recentVisitLines.isEmpty ? "• None recorded" : recentVisitLines.joined(separator: "\n"))
        lines.append("")

        lines.append("Recent symptoms (30 days):")
        lines.append(recentSymptomLines.isEmpty ? "• None recorded" : recentSymptomLines.joined(separator: "\n"))

        return lines.joined(separator: "\n")
    }
}

struct VetSummaryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let summary = VetSummary(appState: appState)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let pet = summary.primaryPet {
                        Text(pet.name)
                            .font(.title.weight(.bold))
                        Text("\(pet.ageText) — \(pet.weightText)")
                            .foregroundStyle(TPColor.muted)
                    } else {
                        Text("No pet on file")
                            .font(.title.weight(.bold))
                        Text("Add a pet to start building summaries.")
                            .foregroundStyle(TPColor.muted)
                    }

                    if summary.weightPoints.count >= 2 {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Weight trend")
                                .font(.headline)
                            WeightChartView(
                                points: summary.weightPoints,
                                unit: summary.primaryPet?.weightUnit.rawValue ?? "kg"
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    summarySection("Active medication", summary.activeMedicationLines.isEmpty ? "None recorded." : summary.activeMedicationLines.joined(separator: "\n"))
                    summarySection("Recent skipped care (30 days)", summary.recentSkippedLines.isEmpty ? "None." : summary.recentSkippedLines.joined(separator: "\n"))
                    summarySection("Weight history (30 days)", summary.weightTrendText)
                    summarySection("Recent symptoms (30 days)", summary.recentSymptomLines.isEmpty ? "None recorded." : summary.recentSymptomLines.joined(separator: "\n"))
                    summarySection("Vaccine history", summary.vaccineHistoryLines.isEmpty ? "None recorded." : summary.vaccineHistoryLines.joined(separator: "\n"))
                    summarySection("Recent visits", summary.recentVisitLines.isEmpty ? "None recorded." : summary.recentVisitLines.joined(separator: "\n"))
                }
                .padding()
            }
            .navigationTitle("Vet Summary")
            .toolbar {
                ShareLink(item: summary.shareText) {
                    Label("Share text", systemImage: "square.and.arrow.up")
                }
                if let pdfURL = VetSummaryPDF.makeFile(
                    title: "\(summary.primaryPet?.name ?? "Pet") — Tend Pets vet summary",
                    body: summary.shareText
                ) {
                    ShareLink(item: pdfURL) {
                        Label("PDF", systemImage: "doc.richtext")
                    }
                }
            }
        }
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

extension RecordType {
    var systemImage: String {
        switch self {
        case .weight: "scalemass"
        case .vaccine: "syringe"
        case .visit: "cross.case"
        case .food: "fork.knife"
        case .note: "note.text"
        case .medicine: "pills"
        case .symptom: "stethoscope"
        }
    }
}
