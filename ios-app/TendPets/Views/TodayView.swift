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

            if appState.todaysOccurrences.isEmpty {
                Section {
                    EmptyStateView(
                        systemImage: "bell.badge",
                        title: "No care due today",
                        message: "Add medication, food, weight, vaccine, or visit reminders so everyone knows what needs attention next.",
                        actionTitle: nil,
                        action: nil
                    )
                }
            } else {
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
                .environmentObject(appState)
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

            if occurrence.status == .done || occurrence.status == .skipped {
                Text(completionText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TPColor.primary)
            } else {
                HStack(spacing: 8) {
                    Button("Done", action: onDone)
                        .buttonStyle(PrimaryPillButtonStyle())
                        .accessibilityLabel("Mark \(plan.name) done for \(pet.name)")
                    Button("Snooze", action: onSnooze)
                        .buttonStyle(NeutralPillButtonStyle())
                        .accessibilityLabel("Snooze \(plan.name) for \(pet.name)")
                    Button("Skip", action: onSkip)
                        .buttonStyle(NeutralPillButtonStyle())
                        .accessibilityLabel("Skip \(plan.name) for \(pet.name)")
                }
            }
        }
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
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

    private var completionText: String {
        switch occurrence.status {
        case .done:
            "Completed by \(occurrence.completedBy ?? "Caregiver")"
        case .skipped:
            "Skipped: \(occurrence.skipReason ?? "No reason")"
        default:
            ""
        }
    }

    private var cardBackground: LinearGradient {
        LinearGradient(colors: [TPColor.primarySoft, .white], startPoint: .top, endPoint: .bottom)
    }
}

struct SnoozeSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notifications: NotificationService
    var occurrence: CareOccurrence
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Snooze reminder")
                .font(.title2.weight(.bold))
            Text("We will remind you again when you have a moment.")
                .foregroundStyle(TPColor.muted)
            HStack {
                Button("10 min") {
                    snooze(minutes: 10)
                }
                    .buttonStyle(PrimaryPillButtonStyle())
                Button("30 min") {
                    snooze(minutes: 30)
                }
                    .buttonStyle(NeutralPillButtonStyle())
                Button("1 hour") {
                    snooze(minutes: 60)
                }
                    .buttonStyle(NeutralPillButtonStyle())
            }
            Spacer()
        }
        .padding()
    }

    private func snooze(minutes: Int) {
        appState.snooze(occurrence, minutes: minutes)
        if let plan = appState.plan(for: occurrence.planId),
           let pet = appState.pet(for: occurrence.petId) {
            Task {
                await notifications.scheduleSnooze(plan: plan, pet: pet, minutes: minutes)
            }
        }
        dismiss()
    }
}

struct PrimaryPillButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(TPColor.primary.opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.35), in: Capsule())
            .foregroundStyle(.white)
    }
}

struct NeutralPillButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6).opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45), in: Capsule())
            .foregroundStyle(isEnabled ? TPColor.text : TPColor.muted)
    }
}
