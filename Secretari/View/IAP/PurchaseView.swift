//
//  PurchaseView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/30.
//

import SwiftUI
import StoreKit

struct PurchaseView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @State private var showCancelSheet = false
    @State private var showPolicy = false
//    @State private var selectedProduct: Product? = nil
//    public static let subscriptionGroupId = "Bunny0"
//    private let features: [String] = ["Remove all ads", "Daily new content", "Other cool features", "Follow for more tutorials"]
    
    var body: some View {
        VStack {
            StoreView(products: subscriptionsManager.products) { product in
                ProductIcon(productId: product.id)
            }
            .background(.background.secondary)
            .padding(.top, 20)
            .inAppPurchaseOptions({ _ in
                // associate this purchase with user id, which will be used as appAccountToken in Transaction
                var purchaseOptions = Set<Product.PurchaseOption>()
                if let user = UserManager.shared.currentUser {
                    let o = Product.PurchaseOption.appAccountToken(UUID(uuidString: user.id) ?? UUID())
                    purchaseOptions.insert(o)
                }
                return purchaseOptions
            })
            .onInAppPurchaseCompletion { product, result in
                // Apple store has finished transacton. After sale process here.
                await subscriptionsManager.buyProduct(product, result: result)
            }
            .productViewStyle(.compact)
            .storeButton(.visible, for: .policies)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.hidden, for: .cancellation)       // hide the top right close button
        }
        HStack {
            Button("How to cancel") {
                showCancelSheet = true
            }
            .padding(.horizontal, 30)
            .font(.subheadline)
            Button("Privacy policies") {
                showPolicy = true
            }
            .font(.subheadline)
        }
        .sheet(isPresented: $showCancelSheet, content: {
            VStack {
                Text("1. Open the Settings app.\n2. Tap your name.\n3. Tap Subscriptions.")
                    .padding(.top, 20)
                Image("Cancel")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/, x: 0, y: 10)
            }
            .presentationDetents([.medium])
            .cornerRadius(20)
        })
        .alert("Privacy policies", isPresented: $showPolicy) {
            Button("OK") {
            }
        } message: {
            Text("We do NOT collect any user information or track user behaviour.")
        }

    }
}

struct ProductIcon: View {
    var productId: String
    
    var body: some View {
        Image(tintById(productId: productId))
            .resizable()
            .frame(width: 50, height: 50)
    }
    
    func tintById(productId: String) -> String {
        // get image name for each product
        if productId.hasPrefix("monthly") {
            return "Monthly"
        }
        else if productId.hasPrefix("Yearly") {
            return "Yearly"
        }
        return "bunny"
    }
}

#Preview {
    PurchaseView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
