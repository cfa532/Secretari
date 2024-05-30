//
//  TransactionManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/30.
//

import Foundation
import StoreKit

class TransactionManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = TransactionManager()
    var productsRequest: SKProductsRequest?
    var availableProducts: [SKProduct] = []

    func fetchProducts(productIds: Set<String>) {
        let request = SKProductsRequest(productIdentifiers: productIds)
        request.delegate = self
        request.start()
        self.productsRequest = request
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.availableProducts = response.products
        // Handle the case where there are no products found
        if availableProducts.isEmpty {
            print("No products available")
        } else {
            for product in availableProducts {
                print("Found product: \(product.localizedTitle) \(product.price)")
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                // Handle successful transaction
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                // Handle failed transaction
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
