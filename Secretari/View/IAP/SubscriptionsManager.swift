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
    var purchasedProductIDs: Set<String> = []

    @Published var purchasedSubscriptions = Set<Product>()
    @Published var purchasedConsumables = [Product]()      // consumables can be repeatedly buy.
//    @Published var entitlements = [Transaction]()
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

        websocket.getProductIDs { dict, statusCode in
            guard let dict = dict, let code=statusCode, code < .failure else {
                print("Failed to get product IDs.", dict as Any)
                // No network connection. Cannot purchase neither.
                return
            }
            print(dict as Any)
            if let ids = dict["ver0"] {
                self.productIDs = ids.split(separator: "|").map(String.init)
            }
        }
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
    func loadProducts() async {
        do {
            self.products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price > $1.price })
        } catch {
            print("Failed to fetch products!")
        }
    }
    
    func buyProduct(_ product: Product, result: Result<Product.PurchaseResult, any Error>) async {
        switch result {
        case .success(let result):
            print(result)
            switch result {
            case .success(.verified(let transaction)):
                // Successful purhcase
                print("puchase successed.", product.id)
                await transaction.finish()
//                print(transaction)
                
                if product.type == .consumable {
                    // recharge account with the amount
                    let purchase: [String: Any] = ["product_id": transaction.productID, "amount": transaction.price as Any, "date": transaction.purchaseDate.timeIntervalSince1970]
                    do {
                        if let json = try await websocket.recharge(purchase) {
                            // edit balance on local record too.
                            print("User from server after recharge", json)      // do not use it for now.
                            userManager.currentUser?.dollar_balance += NSDecimalNumber(decimal: product.price).doubleValue
                            userManager.persistCurrentUser()
                            
//                            await self.updatePurchasedProducts()
                            self.alertItem = AlertContext.rechargeSuccess
                        } else {
                            self.alertItem = AlertContext.unableToComplete
                        }
                        self.showAlert = true
                    } catch {
                        print("Error recharging user account")
                        self.alertItem = AlertContext.unableToComplete
                        self.showAlert = true
                    }
                } else if product.type == .autoRenewable {
                    // set current subscription status
                    print("autorenew", transaction as Any)
                    let sup: [String: Any] = ["product_id": transaction.productID, "start_date": transaction.purchaseDate.timeIntervalSince1970, "end_date": transaction.expirationDate?.timeIntervalSince1970 as Any, "plan": transaction.productType.rawValue, "price": transaction.price as Any]
                    do {
                        if let json = try await websocket.subscribe(sup) {
                            // edit balance on local record too.
                            print("User from server after subscribe", json)
                            userManager.currentUser?.subscription = true
                            userManager.persistCurrentUser()
                            
//                            await self.updatePurchasedProducts()
                            self.alertItem = AlertContext.rechargeSuccess
                        } else {
                            self.alertItem = AlertContext.unableToComplete
                        }
                        self.showAlert = true
                    } catch {
                        print("Error recharging user account")
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
