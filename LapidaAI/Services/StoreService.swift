import Foundation
import StoreKit
import Observation

@Observable
class StoreService {
    static let shared = StoreService()
    
    var products: [Product] = []
    var purchasedProductIDs = Set<String>()
    var isLoadingProducts = false
    
    // ID created in App Store Connect
    private let productIDs = ["com.lapidaai.premium", "com.lapidaai.app.premium"]
    
    init() {
        Task {
            await fetchProducts()
            await updatePurchasedProducts()
            await observeTransactions()
        }
    }
    
    @MainActor
    func fetchProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        do {
            self.products = try await Product.products(for: productIDs)
            print("Produtos carregados: \(products.count)")
        } catch {
            print("Erro ao carregar produtos: \(error)")
        }
        isLoadingProducts = false
    }
    
    func purchase() async throws -> Transaction? {
        if products.isEmpty {
            await fetchProducts()
        }
        
        guard let product = products.first else {
            throw StoreError.productNotFound
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
    }
    
    private func observeTransactions() async {
        for await verification in Transaction.updates {
            guard case .verified(let transaction) = verification else { continue }
            await updatePurchasedProducts()
            await transaction.finish()
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    var premiumProduct: Product? {
        products.first(where: { $0.id == "com.lapidaai.premium" || $0.id == "com.lapidaai.app.premium" })
    }
}

enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedVerification: return "Falha na verificação da compra pela Apple."
        case .productNotFound: return "Produto não encontrado na App Store. Tente novamente em instantes."
        }
    }
}
