import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    enum ProductId {
        static let plusMonthly = "tendpets.plus.monthly"
        static let plusYearly = "tendpets.plus.yearly"
        static let familyMonthly = "tendpets.family.monthly"
        static let familyYearly = "tendpets.family.yearly"
    }

    @Published var products: [Product] = []
    @Published var purchasedProductIds: Set<String> = []
    @Published var isLoading = false
    @Published var message: String?

    var hasPlus: Bool {
        !purchasedProductIds.isDisjoint(with: [
            ProductId.plusMonthly,
            ProductId.plusYearly,
            ProductId.familyMonthly,
            ProductId.familyYearly
        ])
    }

    func start() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedProducts = try await Product.products(for: [
                ProductId.plusMonthly,
                ProductId.plusYearly,
                ProductId.familyMonthly,
                ProductId.familyYearly
            ])
            products = loadedProducts.sorted { first, second in
                productSortIndex(first.id) < productSortIndex(second.id)
            }
        } catch {
            message = "Unable to load subscriptions."
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    purchasedProductIds.insert(transaction.productID)
                    await transaction.finish()
                }
            case .userCancelled:
                break
            case .pending:
                message = "Purchase is pending App Store approval."
            @unknown default:
                message = "Purchase could not be completed."
            }
        } catch {
            message = "No charge was made. Please try again."
        }
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

    func refreshEntitlements() async {
        purchasedProductIds.removeAll()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIds.insert(transaction.productID)
            }
        }
    }
}
