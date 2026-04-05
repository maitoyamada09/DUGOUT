import Foundation
import StoreKit

/// Manages In-App Purchases using StoreKit 2
@Observable
final class StoreManager {

    // MARK: - Product IDs
    static let proMonthlyID = "com.maitoyamada.DUGOUT.pro.monthly"
    static let proYearlyID  = "com.maitoyamada.DUGOUT.pro.yearly"

    // MARK: - State
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var errorMessage: String? = nil

    /// Whether the user has an active Pro subscription
    var isPro: Bool {
        !purchasedProductIDs.isEmpty
    }

    // MARK: - Init
    init() {
        // Start listening for transaction updates
        Task {
            await listenForTransactions()
        }
    }

    // MARK: - Load Products
    @MainActor
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            let productIDs: Set<String> = [
                Self.proMonthlyID,
                Self.proYearlyID
            ]
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            errorMessage = "製品情報の取得に失敗しました"
            isLoading = false
        }
    }

    // MARK: - Purchase
    @MainActor
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Restore Purchases
    @MainActor
    func restorePurchases() async {
        var restored: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                restored.insert(transaction.productID)
            }
        }
        purchasedProductIDs = restored
    }

    // MARK: - Check Entitlements on Launch
    @MainActor
    func checkEntitlements() async {
        var entitled: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                entitled.insert(transaction.productID)
            }
        }
        purchasedProductIDs = entitled
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await MainActor.run {
                    purchasedProductIDs.insert(transaction.productID)
                }
                await transaction.finish()
            }
        }
    }

    // MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
