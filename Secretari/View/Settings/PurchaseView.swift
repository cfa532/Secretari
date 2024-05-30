//
//  PurchaseView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/30.
//

import SwiftUI

struct PurchaseView: View {
    @ObservedObject var transactionManager = TransactionManager.shared
    
    var body: some View {
        List(transactionManager.availableProducts, id: \.productIdentifier) { product in
            VStack(alignment: .leading) {
                Text(product.localizedTitle)
                Text(product.localizedDescription)
                Button("Buy") {
                    transactionManager.buyProduct(product)
                }
            }
        }
        .onAppear {
            let productIds: Set<String> = ["240529", "24052901"]
            transactionManager.fetchProducts(productIds: productIds)
        }    }
}

#Preview {
    PurchaseView()
}
