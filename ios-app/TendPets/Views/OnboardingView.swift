import SwiftUI

private struct OnboardingStep: Identifiable {
    let id = UUID()
    let eyebrow: String
    let title: String
    let body: String
    let proof: String
    let cards: [OnboardingCard]
}

private struct OnboardingCard: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

struct OnboardingView: View {
    var isReplay: Bool
    var onSkip: () -> Void
    var onFinish: () -> Void

    @State private var stepIndex = 0

    private let steps = [
        OnboardingStep(
            eyebrow: "Why it matters",
            title: "Care is hard to remember when life is already full.",
            body: "Medication, food changes, weight shifts, vaccines, and vet visits all live in different places. Tend Pets turns them into one calm daily routine.",
            proof: "0 missed routines is the goal",
            cards: [
                OnboardingCard(title: "Medication", detail: "Know what is due, done, snoozed, or skipped."),
                OnboardingCard(title: "Visits", detail: "Keep notes ready before the appointment.")
            ]
        ),
        OnboardingStep(
            eyebrow: "Today first",
            title: "Open the app and know exactly what needs care next.",
            body: "The Today screen is built for busy mornings: one pet, one due card, and three clear actions.",
            proof: "Done, Snooze, Skip",
            cards: [
                OnboardingCard(title: "Done", detail: "Record who completed the care."),
                OnboardingCard(title: "Snooze", detail: "Move a reminder without losing it.")
            ]
        ),
        OnboardingStep(
            eyebrow: "For family and vets",
            title: "A cleaner handoff when more than one person helps.",
            body: "Shared care notes reduce duplicate messages, and records become a simple vet summary instead of a memory test.",
            proof: "Vet-ready history",
            cards: [
                OnboardingCard(title: "Family", detail: "See who completed each routine."),
                OnboardingCard(title: "Records", detail: "Medication, weight, visit, and vaccine history.")
            ]
        ),
        OnboardingStep(
            eyebrow: "Start small",
            title: "Add one pet and one routine. That is enough to begin.",
            body: "You do not need to organize everything today. Start with the care task that would be worst to forget.",
            proof: "First reminder in under a minute",
            cards: [
                OnboardingCard(title: "Momo", detail: "Example pet profile is ready."),
                OnboardingCard(title: "Heart med", detail: "Use this as your first medication routine.")
            ]
        )
    ]

    private var currentStep: OnboardingStep {
        steps[stepIndex]
    }

    private var isLastStep: Bool {
        stepIndex == steps.count - 1
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [TPColor.primarySoft, TPColor.groupedBackground],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                topBar

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 18) {
                    Text(currentStep.eyebrow.uppercased())
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(TPColor.primary)

                    Text(currentStep.title)
                        .font(.system(size: 38, weight: .bold, design: .default))
                        .foregroundStyle(TPColor.text)
                        .lineSpacing(-2)
                        .minimumScaleFactor(0.86)

                    Text(currentStep.body)
                        .font(.body)
                        .foregroundStyle(TPColor.muted)
                        .lineSpacing(3)

                    Text(currentStep.proof)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(TPColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(TPColor.surface.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(TPColor.primary.opacity(0.18), lineWidth: 1)
                        )

                    HStack(spacing: 10) {
                        ForEach(currentStep.cards) { card in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(card.title)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(TPColor.text)
                                Text(card.detail)
                                    .font(.footnote)
                                    .foregroundStyle(TPColor.muted)
                                    .lineSpacing(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
                            .padding(14)
                            .background(TPColor.surface, in: RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }

                Spacer(minLength: 8)

                progressDots
                actions
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 22)
        }
        .accessibilityElement(children: .contain)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 10) {
                CareRingView(progress: 0.82, initial: "M")
                    .frame(width: 38, height: 38)
                Text("Tend Pets")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(TPColor.text)
            }

            Spacer()

            Button(isReplay ? "Skip" : "Skip for now") {
                onSkip()
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(TPColor.primary)
            .frame(minHeight: 44)
        }
    }

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(steps.indices, id: \.self) { index in
                Capsule()
                    .fill(index == stepIndex ? TPColor.primary : Color(.systemGray4))
                    .frame(width: index == stepIndex ? 22 : 7, height: 7)
            }
        }
        .animation(.easeInOut(duration: 0.16), value: stepIndex)
    }

    private var actions: some View {
        HStack(spacing: 10) {
            if stepIndex > 0 {
                Button("Back") {
                    stepIndex = max(stepIndex - 1, 0)
                }
                .buttonStyle(NeutralPillButtonStyle())
            } else {
                Color.clear.frame(height: 50)
            }

            Button(isLastStep ? "Add first care" : "Continue") {
                if isLastStep {
                    onFinish()
                } else {
                    stepIndex = min(stepIndex + 1, steps.count - 1)
                }
            }
            .buttonStyle(PrimaryPillButtonStyle())
        }
    }
}
