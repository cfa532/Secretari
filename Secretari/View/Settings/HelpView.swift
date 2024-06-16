//
//  HelpView.swift
//  Secretari
//
//  Created by 超方 on 2024/6/16.
//

import SwiftUI

struct HelpView: View {
    private let websocket = Websocket.shared
    @State private var notice: String?
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Notice")) {
                    if let notice = notice {
                        Text(notice)
                    }
                }
                Section(header: Text("How-to")) {
                    Text("This App generates summary out of transcripts of user speech by calling the best AI service. There are two types of summaries, ")
                }
                Section(header: Text("Policy")) {
                    Text("In regarding to cancellation and refund, this App follows the policies of Apple store. With one extra restriction on the usage cap of the subscribers, which limits the monthly expense of a subscriber to about twice of the expense we are paying OpenAI for using its API. If a subscriber is over the limit, the one-time purchase of tokens can be made to continue the use of this App.")
                }
            }
        }
        .navigationTitle("Bulletin Board")
        .onAppear {
            loadNotice()
        }
    }
    
    private func loadNotice() {
        Task {
            if let fetchedNotice = try await websocket.getNotice() {
                print(fetchedNotice as Any)
                notice = fetchedNotice
            }
        }
    }
}

#Preview {
    HelpView()
}
