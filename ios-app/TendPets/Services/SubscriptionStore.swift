import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    enum ProductId {
        static let plusMonthly = "tendpets.plus.monthly"
        static let plusYearly = "tendpets.plus.yearly"
        static let familyMonthly = "tendpets.family.monthly"
        static let familyYearly = "tendpets.family.yearly"

        static let all: Set<String> = [plusMonthly, plusYearly, familyMonthly, familyYearly]
    }

    @Published var products: [Product] = []
    @Published var purchasedProductIds: Set<String> = []
    @Published var isLoading = false
    /// The product whose App Store purchase sheet is currently in flight, or nil.
    /// Per-product (not a global bool) so only the tapped row shows "Processing…"
    /// while the other rows keep showing their price.
    @Published var purchasingProductId: String?
    @Published var message: String?

    /// True while any purchase is in flight (used to disable Close / Restore).
    var isPurchasing: Bool { purchasingProductId != nil }

    /// Whether the customer can still get the free-trial intro offer. Apple
    /// grants the intro offer once per subscription group, and only in
    /// territories where the offer is configured. Drives the paywall CTA so we
    /// never promise a "free month" to someone who won't actually get one
    /// (avoids a misleading offer — App Review Guideline 3.1.2).
    @Published var introOfferEligible = true

    /// End date of the customer's current free-trial period, or nil if they are
    /// not currently in a trial. Drives the "Plus trial — X days left" status.
    @Published var trialEndDate: Date?

    /// Whole days remaining in the current free trial (nil if not in a trial).
    var trialDaysLeft: Int? {
        guard let end = trialEndDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(0, days)
    }

    private var updatesTask: Task<Void, Never>?

    var hasPlus: Bool {
        !purchasedProductIds.isDisjoint(with: ProductId.all)
    }

    func start() async {
        await loadProducts()
        await refreshEntitlements()
        startTransactionListener()
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedProducts = try await Product.products(for: Array(ProductId.all))
            products = loadedProducts.sorted { first, second in
                productSortIndex(first.id) < productSortIndex(second.id)
            }
            // Intro-offer eligibility is per subscription group; all four plans
            // share one group, so any product's subscription answers it.
            if let subscription = products.first(where: { $0.subscription != nil })?.subscription {
                introOfferEligible = await subscription.isEligibleForIntroOffer
            }
        } catch {
            message = "Unable to load subscriptions. Please check your connection and try again."
        }
    }

    func purchase(_ product: Product) async {
        guard purchasingProductId == nil else { return }
        purchasingProductId = product.id
        defer { purchasingProductId = nil }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    purchasedProductIds.insert(transaction.productID)
                    await transaction.finish()
                    message = "You're in. Tend Pets Plus is unlocked."
                } else {
                    message = "Purchase could not be verified. Please contact support."
                }
            case .userCancelled:
                break
            case .pending:
                message = "Purchase is pending — we'll unlock features once Apple approves it."
            @unknown default:
                message = "Purchase could not be completed."
            }
        } catch {
            message = "No charge was made. Please try again."
        }
    }

    func refreshEntitlements() async {
        var current: Set<String> = []
        var trialEnd: Date?
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                current.insert(transaction.productID)
                // Detect an active free-trial period so the UI can show a countdown.
                if transaction.offerType == .introductory,
                   let expiration = transaction.expirationDate, expiration > Date() {
                    trialEnd = expiration
                }
            }
        }
        // Assign once at the end to avoid the UI briefly showing hasPlus = false
        // during a slow network restore.
        purchasedProductIds = current
        trialEndDate = trialEnd
    }

    private func startTransactionListener() {
        // Apple recommends listening to Transaction.updates so subscription
        // changes made outside the app (auto-renew, cancellation, refund,
        // family-sharing entitlement changes) are reflected immediately.
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await self.applyVerifiedUpdate(transaction)
                }
            }
        }
    }

    private func applyVerifiedUpdate(_ transaction: Transaction) async {
        if transaction.revocationDate != nil || transaction.isUpgraded {
            await refreshEntitlements()
        } else if transaction.expirationDate.map({ $0 < Date() }) ?? false {
            await refreshEntitlements()
        } else {
            purchasedProductIds.insert(transaction.productID)
        }
        await transaction.finish()
    }

    private func productSortIndex(_ id: String) -> Int {
        switch id {
        case ProductId.plusMonthly: 0
        case ProductId.plusYearly: 1
        case ProductId.familyMonthly: 2
        case ProductId.familyYearly: 3
        default: 99
        }
    }
}
