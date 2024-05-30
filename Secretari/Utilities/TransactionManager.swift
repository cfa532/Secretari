//
//  TransactionManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/30.
//

import Foundation
import StoreKit

class TransactionManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, ObservableObject {
    static let shared = TransactionManager()
    @Published var availableProducts: [SKProduct] = []

    var productsRequest: SKProductsRequest?

    func fetchProducts(productIds: Set<String>) {
        let request = SKProductsRequest(productIdentifiers: productIds)
        request.delegate = self
        request.start()
        self.productsRequest = request
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.availableProducts = response.products
            if self.availableProducts.isEmpty {
                print("No products available")
            } else {
                for product in self.availableProducts {
                    print("Found product: \(product.localizedTitle) \(product.price)")
                }
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }

    func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}
