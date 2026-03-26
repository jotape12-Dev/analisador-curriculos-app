import Foundation
import StoreKit
import Observation

@Observable
class StoreService {
    static let shared = StoreService()
    
    var products: [Product] = []
    var purchasedProductIDs = Set<String>()
    
    // ID que você deve criar no App Store Connect
    private let productIDs = ["com.lapidaai.premium"]
    
    init() {
        Task {
            await fetchProducts()
            await updatePurchasedProducts()
        }
    }
    
    @MainActor
    func fetchProducts() async {
        do {
            self.products = try await Product.products(for: productIDs)
            print("Produtos carregados: \(products.count)")
        } catch {
            print("Erro ao carregar produtos: \(error)")
        }
    }
    
    func purchase() async throws -> Transaction? {
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
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
    case productNotFound
}
