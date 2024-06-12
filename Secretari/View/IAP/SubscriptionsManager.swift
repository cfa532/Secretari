//
//  SubscriptionManager.swift
//  storekit-2-demo-app
//
//  Created by Aisultan Askarov on 11.01.2024.
//

import StoreKit
import SwiftUI

@MainActor
class SubscriptionsManager: NSObject, ObservableObject {
    var productIDs: [String] = []
    var purchasedProductIDs: Set<String> = []       // if empty, not purchase

    @Published var purchasedSubscriptions = Set<Product>()
    @Published var purchasedConsumables = [Product]()      // consumables can be repeatedly buy.
    // @Published var entitlements = [Transaction]()
    @Published var products: [Product] = []
    
    @Published var showAlert = false
    @Published var alertItem: AlertItem?
    
    private var entitlementManager: EntitlementManager? = nil
    private var updates: Task<Void, Never>? = nil
    private var userManager = UserManager.shared
    private var websocket = Websocket.shared
    
    init(entitlementManager: EntitlementManager) {
        super.init()
        self.entitlementManager = entitlementManager
        self.updates = observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        updates?.cancel()
    }
    
    func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await self.updatePurchasedProducts()
            }
        }
    }
    
    @MainActor
    func requestProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print(error)
        }
    }
}

// MARK: StoreKit2 API
extension SubscriptionsManager {
    func loadProducts() {
        websocket.getProductIDs { dict, statusCode in
            guard let dict = dict, let code=statusCode, code < .failure else {
                print("Failed to get product IDs.", dict as Any)
                // No network connection. Cannot purchase neither.
                return
            }
            if let dict = dict["ver0"] as? [String: Any] {
                if let ids = dict["productIDs"] as? [String: Double] {
                    self.productIDs = ids.keys.map{ $0 as String }
                    print("productIDs", self.productIDs)
                    Task { @MainActor in
                        self.products = try await Product.products(for: self.productIDs)
                            .sorted(by: { $0.price > $1.price })
                    }
                }
                if let llmModel = dict["llmModel"] as? String {
                    print("LLModel", llmModel)
                    let sm = SettingsManager.shared
                    var setting = sm.getSettings()
                    setting.llmModel = LLMModel(rawValue: llmModel) ?? AppConstants.PrimaryModel
                    sm.updateSettings(setting)
                }
            }
        }
    }
    
    func syncRetry(_ purchase: [String: Any], retries: Int = 3) async throws -> Void {
        var attempts = 0
        var delay: UInt64 = 1
        
        while attempts < retries {
            do {
                if let json = try await websocket.recharge(purchase), let balance=json["dollar_balance"] as? Double {
                    // edit balance on local record too.
                    print("User from server after recharge", json)      // do not use it for now.
                    userManager.currentUser?.dollar_balance = balance
                    userManager.currentUser?.balance_synced = true
                    userManager.persistCurrentUser()
                }
            } catch {
                attempts += 1
                if attempts >= retries {
                    throw error
                }
                try await Task.sleep(nanoseconds: delay * 1_000_000_000) // Convert seconds to nanoseconds
                delay *= 2 // Exponential backoff
            }
        }
        throw URLError(.cannotLoadFromNetwork)
    }
    
    func buyProduct(_ product: Product, result: Result<Product.PurchaseResult, any Error>) async {
        switch result {
        case .success(let result):
            switch result {
            case .success(.verified(let transaction)):
                // Successful purhcase
                print("puchase successed.", transaction)
                await transaction.finish()
//                print(transaction)
                
                if product.type == .consumable {
                    // recharge account with the amount
                    userManager.currentUser?.balance_synced = false
                    userManager.persistCurrentUser()
                    let purchase: [String: Any] = ["product_id": transaction.productID, "amount": transaction.price! as Any, "currency":transaction.currency!.identifier as Any, "transactionDate": transaction.originalPurchaseDate.timeIntervalSince1970, "originalTransactionID": transaction.originalID, "version":"ver0", "appAccountToken": transaction.appAccountToken?.uuidString as Any]    // original transaction ID very important
                    print(purchase)
                    do {
                        if let json = try await websocket.recharge(purchase), let balance=json["dollar_balance"] as? Double {
                            // edit balance on local record too.
                            print("User from server after recharge", json)      // do not use it for now.
                            userManager.currentUser?.dollar_balance = balance
                            userManager.currentUser?.balance_synced = true
                            userManager.persistCurrentUser()
                        }
                    } catch {
                        print("Error recharge. Retry....")
                        // recharge to server failed. Retry the next time when
                        do {
                            try await self.syncRetry(purchase)
                        } catch {
                            print("Error sending consumble purchase data to server.")
                        }
                    }
                } else if product.type == .autoRenewable {
                    // set current subscription status
                    let sup: [String: Any] = ["product_id": transaction.productID, "start_date": transaction.purchaseDate.timeIntervalSince1970, "end_date": transaction.expirationDate?.timeIntervalSince1970 as Any, "plan": transaction.productType.rawValue, "price": transaction.price as Any, "originalID": transaction.originalID, "version":"ver0", "appAccountToken": transaction.appAccountToken?.uuidString as Any]
                    do {
                        if let json = try await websocket.subscribe(sup) {
                            // edit balance on local record too.
                            print("User from server after subscribe", json)
//                            userManager.currentUser?.subscription = true
//                            userManager.persistCurrentUser()                            
                            await self.updatePurchasedProducts()
                        }
                    } catch {
                        print("Error update subscription status")
                        self.alertItem = AlertContext.unableToComplete
                        self.showAlert = true
                    }
                }
            case let .success(.unverified(_, error)):
                // Successful purchase but transaction/receipt can't be verified
                // Could be a jailbroken phone
                print("Unverified purchase. Might be jailbroken. Error: \(error)")
                break
            case .pending:
                // Transaction waiting on SCA (Strong Customer Authentication) or
                // approval from Ask to Buy
                break
            case .userCancelled:
                print("User cancelled!")
                break
            @unknown default:
                print("Failed to purchase the product!")
                break
            }
        case .failure(let error):
            print(error)
        }
    }
    
    // watch for user's entitlements in case purchased somewhere else.
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
        self.entitlementManager?.hasPro = !self.purchasedProductIDs.isEmpty
//        self.userManager.currentUser?.subscription = !self.purchasedProductIDs.isEmpty
//        userManager.persistCurrentUser()
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print(error)
        }
    }
}

extension SubscriptionsManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}
