import Foundation
import StoreKit

/// Main class for managing in-app purchases and subscriptions on iOS
/// Integrates with Apple's StoreKit framework to handle product retrieval,
/// purchasing, and subscription management
@objc(Subscriptions)
public class Subscriptions: NSObject {
    
    // MARK: - Properties
    
    /// Shared singleton instance
    @objc public static let shared = Subscriptions()
    
    private var productsRequest: SKProductsRequest?
    private var completionHandler: (([SKProduct], Error?) -> Void)?
    private var purchaseCompletionHandler: ((SKPaymentTransaction?, Error?) -> Void)?
    private var restoreCompletionHandler: (([SKPaymentTransaction]?, Error?) -> Void)?
    
    /// Track purchased products and their receipts
    private var purchasedProducts: [String: SKPaymentTransaction] = [:]
    
    /// Track active subscriptions with their expiry dates
    private var activeSubscriptions: [String: Date] = [:]
    
    // MARK: - Init
    
    /// Register the payment queue observer
    /// Should be called early in the app lifecycle
    @objc public static func register() {
        SKPaymentQueue.default().add(Subscriptions.shared)
    }
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Retrieve products from the App Store
    /// - Parameters:
    ///   - productIdentifiers: Array of product IDs to fetch
    ///   - completion: Callback with products and optional error
    @objc public func getProducts(_ productIdentifiers: [String], completion: @escaping ([SKProduct], Error?) -> Void) {
        self.completionHandler = completion
        
        let request = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        request.delegate = self
        request.start()
        
        self.productsRequest = request
    }
    
    /// Initiate a purchase for a product
    /// - Parameters:
    ///   - product: The SKProduct to purchase
    ///   - completion: Callback with transaction result and optional error
    @objc public func purchaseProduct(_ product: SKProduct, completion: @escaping (SKPaymentTransaction?, Error?) -> Void) {
        guard SKPaymentQueue.canMakePayments() else {
            let error = NSError(
                domain: "com.tauri.subscriptions",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "In-app purchases are not allowed on this device"]
            )
            completion(nil, error)
            return
        }
        
        self.purchaseCompletionHandler = completion
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    /// Restore previously purchased items
    /// - Parameter completion: Callback with restored transactions and optional error
    @objc public func restorePurchases(completion: @escaping ([SKPaymentTransaction]?, Error?) -> Void) {
        self.restoreCompletionHandler = completion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    /// Get the subscription status for a product
    /// - Parameter productId: Product identifier to check
    /// - Returns: Dictionary with subscription status information
    @objc public func getSubscriptionStatus(_ productId: String) -> [String: Any] {
        var status: [String: Any] = [
            "productId": productId,
            "isActive": false,
            "expiryDate": NSNull(),
            "autoRenewStatus": false,
            "isInTrialPeriod": false,
            "isInGracePeriod": false
        ]
        
        if let expiryDate = activeSubscriptions[productId] {
            let isActive = expiryDate > Date()
            status["isActive"] = isActive
            status["expiryDate"] = expiryDate.timeIntervalSince1970
            
            // These values would need to be extracted from receipt validation in a real implementation
            status["autoRenewStatus"] = true
            status["isInTrialPeriod"] = false
            status["isInGracePeriod"] = false
        }
        
        return status
    }
    
    /// Check if a subscription is currently active
    /// - Parameter productId: Product identifier to check
    /// - Returns: Boolean indicating if the subscription is active
    @objc public func isSubscriptionActive(_ productId: String) -> Bool {
        guard let expiryDate = activeSubscriptions[productId] else {
            return false
        }
        return expiryDate > Date()
    }
    
    // MARK: - Helper Methods
    
    /// Validate and process a transaction receipt
    /// In a production app, this should validate with Apple's servers
    /// - Parameter transaction: The transaction to validate
    private func validateReceipt(forTransaction transaction: SKPaymentTransaction) {
        // In a real app, you would implement App Store receipt validation here
        // For now, we'll simulate subscription expiry dates
        
        let productId = transaction.payment.productIdentifier
        
        if productId.contains("subscription") {
            // Set expiry to 1 month from now for demo purposes
            let expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            activeSubscriptions[productId] = expiryDate
        } else {
            // For non-subscription purchases, just mark as purchased
            purchasedProducts[productId] = transaction
        }
    }
}

// MARK: - SKProductsRequestDelegate

extension Subscriptions: SKProductsRequestDelegate {
    /// Called when products are successfully retrieved
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.completionHandler?(response.products, nil)
            self.completionHandler = nil
            self.productsRequest = nil
        }
    }
    
    /// Called when product request fails
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.completionHandler?([], error)
            self.completionHandler = nil
            self.productsRequest = nil
        }
    }
}

// MARK: - SKPaymentTransactionObserver

extension Subscriptions: SKPaymentTransactionObserver {
    /// Called when transactions are updated in the payment queue
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Validate and finish the transaction
                validateReceipt(forTransaction: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)
                purchaseCompletionHandler?(transaction, nil)
                purchaseCompletionHandler = nil
                
            case .failed:
                // Finish failed transaction and notify
                SKPaymentQueue.default().finishTransaction(transaction)
                purchaseCompletionHandler?(nil, transaction.error)
                purchaseCompletionHandler = nil
                
            case .restored:
                // Validate and finish restored transaction
                validateReceipt(forTransaction: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .purchasing, .deferred:
                // Transaction is in progress, do nothing
                break
                
            @unknown default:
                break
            }
        }
    }
    
    /// Called when restore transactions completes successfully
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        let restoredTransactions = queue.transactions.filter { $0.transactionState == .restored }
        
        for transaction in restoredTransactions {
            validateReceipt(forTransaction: transaction)
        }
        
        DispatchQueue.main.async {
            self.restoreCompletionHandler?(restoredTransactions, nil)
            self.restoreCompletionHandler = nil
        }
    }
    
    /// Called when restore transactions fails
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        DispatchQueue.main.async {
            self.restoreCompletionHandler?(nil, error)
            self.restoreCompletionHandler = nil
        }
    }
}