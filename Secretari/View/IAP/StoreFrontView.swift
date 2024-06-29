//
//  StoreFront.swift
//  Secretari
//
//  Created by 超方 on 2024/6/26.
//

import SwiftUI
import StoreKit

struct StoreFrontView: View {
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @State private var showStore = false
    
    var body: some View {
        List {
            if let i = subscriptionsManager.products.firstIndex(where: {$0.id == "monthly.bunny0"}) {
                let product = subscriptionsManager.products[i]
                ProductView(iconName: "Monthly", title: product.displayName, price: product.displayPrice,
                            description: "One month, auto-renewable service. User gets an AI assistant powered by OpenAI's most advanced GPT model, it meticulously records all your speeches, lectures, and instructions to create comprehensive summaries. Empower your business and simplify your life.")
            }
            if let i = subscriptionsManager.products.firstIndex(where: {$0.id == "Yearly.bunny0"}) {
                let product = subscriptionsManager.products[i]
                ProductView(iconName: "Yearly", title: product.displayName, price: product.displayPrice,
                            description: "One full year, auto-renewable service. User enjoys a 20% discount compared with monthly plan.")
            }
            if let i = subscriptionsManager.products.firstIndex(where: {$0.id == "890842"}) {
                let product = subscriptionsManager.products[i]
                ProductView(iconName: "bunny", title: product.displayName, price: product.displayPrice,
                            description: "Purchase consumable tokens that cover approximately a quarter million words. Users receive uninterrupted AI assistant service on an as-needed basis, making it ideal for occasional users.")
            }
            Section {
                Button(action: {
                    showStore = true
                }, label: {
                    RoundedRectangle(cornerRadius: 12.5)
                        .overlay {
                            Text("Purchase")
                                .foregroundStyle(.white)
                                .font(.system(size: 16.5, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 46)
                })
                .sheet(isPresented: $showStore, content: {
                    PurchaseView()
                })

            }
        }
    }
}


struct ProductView: View {
    var iconName: String
    var title: String
    var price: String
    var description: String
    
    var body: some View {
        HStack {
            Image(iconName)
                .resizable()
                .frame(width: 40, height: 40)
            VStack {
                Text(LocalizedStringKey(title))
                    .font(.title3)
                Text(price)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        Text(LocalizedStringKey(description))
            .font(.subheadline)
    }
}

#Preview {
    StoreFrontView()
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
