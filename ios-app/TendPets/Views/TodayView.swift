import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: SubscriptionStore
    @State private var snoozeOccurrence: CareOccurrence?
    @State private var skipOccurrence: CareOccurrence?
    @State private var showSkipSheet = false
    @State private var showQuickLog = false

    var body: some View {
        List {
            if let pet = appState.pets.first {
                Section {
                    HStack(spacing: 12) {
                        CareRingView(progress: todayProgress, initial: String(pet.name.prefix(1)), photoName: pet.photoName)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(pet.name)
                                    .font(.headline)
                                if pet.isSample {
                                    Text("SAMPLE")
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(TPColor.primarySoft, in: Capsule())
                                        .foregroundStyle(TPColor.primary)
                                }
                            }
                            Text(pet.isSample ? "Sample data — add your pet to begin" : todaySummaryText)
                                .font(.subheadline)
                                .foregroundStyle(TPColor.muted)
                        }
                        Spacer()
                        Text("\(Int(todayProgress * 100))%")
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
                    ForEach(dueOccurrences) { occurrence in
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

            if !laterTodayOccurrences.isEmpty {
                Section("Later today") {
                    ForEach(laterTodayOccurrences) { occurrence in
                        if let plan = appState.plan(for: occurrence.planId),
                           let pet = appState.pet(for: occurrence.petId) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(pet.name)'s \(plan.name)")
                                    Text(formatTime(occurrence.dueAt))
                                        .font(.caption)
                                        .foregroundStyle(TPColor.muted)
                                }
                            } icon: {
                                Image(systemName: plan.type.systemImage)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Today")
        .scrollContentBackground(.hidden)
        .background(TPColor.groupedBackground)
        .toolbar {
            if !appState.pets.isEmpty {
                Button {
                    showQuickLog = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Quick log weight or symptom")
            }
        }
        .sheet(isPresented: $showQuickLog) {
            QuickLogSheet().environmentObject(appState).environmentObject(store)
        }
        .sheet(item: $snoozeOccurrence) { occurrence in
            SnoozeSheet(occurrence: occurrence)
                .environmentObject(appState)
                .presentationDetents([.height(240)])
        }
        .confirmationDialog("Skip reason", isPresented: $showSkipSheet, titleVisibility: .visible) {
            Button("Not eating") { recordSkip(reason: "Not eating") }
            Button("Vet instructed") { recordSkip(reason: "Vet instructed") }
            Button("Already given") { recordSkip(reason: "Already given") }
            Button("Other") { recordSkip(reason: "Other") }
            Button("Cancel", role: .cancel) { skipOccurrence = nil }
        } message: {
            Text("Tend Pets will record why care was skipped for vet history.")
        }
    }

    // MARK: - Today computed properties

    private var todaysAll: [CareOccurrence] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return appState.occurrences.filter {
            calendar.isDate($0.dueAt, inSameDayAs: today)
        }
    }

    private var todayDone: Int {
        todaysAll.filter { $0.status == .done }.count
    }

    private var todayTotal: Int {
        todaysAll.count
    }

    private var todayProgress: Double {
        guard todayTotal > 0 else { return 0 }
        return Double(todayDone) / Double(todayTotal)
    }

    private var todaySummaryText: String {
        let dateText = Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        if todayTotal == 0 {
            return "\(dateText) — no care scheduled"
        }
        return "\(dateText) — \(todayDone) of \(todayTotal) done"
    }

    private var dueOccurrences: [CareOccurrence] {
        appState.todaysOccurrences.filter {
            $0.status == .due || $0.status == .missed || $0.status == .done || $0.status == .skipped
        }
        .filter {
            // Only show items that are due now or recently overdue (in the past).
            $0.dueAt <= Date().addingTimeInterval(60)
        }
    }

    private var laterTodayOccurrences: [CareOccurrence] {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        return appState.occurrences
            .filter { $0.dueAt > now && $0.dueAt <= endOfDay }
            .filter { $0.status == .upcoming || $0.status == .due }
            .sorted { $0.dueAt < $1.dueAt }
    }

    private func formatTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func recordSkip(reason: String) {
        if let skipOccurrence {
            appState.skip(skipOccurrence, reason: reason)
        }
        skipOccurrence = nil
    }
}

private extension CareType {
    var systemImage: String {
        switch self {
        case .medicine: "pills"
        case .food: "fork.knife"
        case .weight: "scalemass"
        case .visit: "cross.case"
        case .vaccine: "syringe"
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
            Text(plan.detail.isEmpty ? "No additional notes" : plan.detail)
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
