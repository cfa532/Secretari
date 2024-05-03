//
//  UserManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/2.
//

import Foundation

class UserManager: ObservableObject {
  @Published var currentUser: User?

  func loadUser() {
    // Load user data from persistent storage (optional)
    currentUser = User(id: "user123", tokens: 0, subscription: false) // Placeholder for initial data
  }

  func awardSignupBonus() {
    guard var user = currentUser else { return }
    user.tokens += user.signupBonus
    currentUser = user
  }

  func updateSubscriptionStatus(isSubscribed: Bool) {
    guard var user = currentUser else { return }
    user.subscription = isSubscribed
    currentUser = user
  }

  func addTokens(amount: Int) {
    guard var user = currentUser else { return }
    user.tokens += amount
    currentUser = user
  }

  func deductTokens(amount: Int) {
    guard var user = currentUser else { return }
    user.tokens = max(user.tokens - amount, 0) // Ensure tokens don't go negative
    currentUser = user
  }
}

struct User {
  let id: String // Unique identifier for the user
  var tokens: Int
  var subscription: Bool // Flag indicating active subscription
  let signupBonus: Int = 100 // Signup bonus amount (constant)
}
