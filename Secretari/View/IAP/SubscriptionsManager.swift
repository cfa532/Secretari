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
    
    private var appProducts: [String: Double] = [String: Double]()
    private var entitlementManager: EntitlementManager?
    private var updates: Task<Void, Never>?
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
    func loadDefaultsFromServer() {
        websocket.getProductIDs { dict, statusCode in
            guard let dict = dict, let code=statusCode, code < .failure else {
                print("Failed to get product IDs.", dict as Any)
                // No network connection. Cannot purchase neither.
                return
            }
            // "productIDs":{"890842":8.99,"Yearly.bunny0":89.99,"monthly.bunny0":8.99}
            if let dict = dict["ver0"] as? [String: Any] {
                if let ids = dict["productIDs"] as? [String: Double] {
                    self.productIDs = ids.keys.map{ $0 as String }
                    self.appProducts = ids
                    print("productIDs", self.appProducts as Any)
                    Task { @MainActor in
                        self.products = try await Product.products(for: self.productIDs)
                            .sorted(by: { $0.id > $1.id })
                    }
                }
            }
        }
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
                    // assume the purchase succeed, update account balance on device now.
                    // the balance will be updated from server data every time the service is used.
                    if let balance = userManager.currentUser?.dollar_balance, let price = self.appProducts[product.id] {
                        userManager.currentUser?.dollar_balance = balance + price
                        userManager.persistCurrentUser()
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
        print("Subscriber,", self.entitlementManager?.hasPro as Any)
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
