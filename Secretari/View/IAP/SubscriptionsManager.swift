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
            case let .success(.verified(transaction)):
                // Successful purhcase
                print("puchase successed.", product.id)
                await transaction.finish()
                
                if product.type == .consumable {
                    // recharge account with the amount
                    let nsDecimalNumber = NSDecimalNumber(decimal: product.price)
                    let purchase: [String: String] = ["product_id": product.id, "amount": String(describing: nsDecimalNumber), "date": String(describing: Date().timeIntervalSince1970)]
                    do {
                        if try await websocket.recharge(purchase) != nil {
                            // edit balance on local record too.
                            print("recharge price", nsDecimalNumber.doubleValue)
                            userManager.currentUser?.dollar_balance += nsDecimalNumber.doubleValue
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
                    let sup: [String: String] = ["product_id": product.id, "start_date": String(describing: Date().timeIntervalSince1970), "plan": product.type.rawValue]
                    do {
                        if try await websocket.subscribe(sup) != nil {
                            // edit balance on local record too.
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
