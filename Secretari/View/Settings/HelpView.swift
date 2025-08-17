//
//  HelpView.swift
//  Secretari
//
//  Created by 超方 on 2024/6/16.
//

import SwiftUI

struct HelpView: View {
    @State private var notice: String = "Thank you for using our services."
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(LocalizedStringKey("Notice"))) {
                        Text(notice)
                }
                Section(header: Text(LocalizedStringKey("How-to"))) {
                    Text(LocalizedStringKey("This app generates summaries from user speech transcripts by utilizing a top-tier AI service. There are two types of summaries available: a standard summary and a checklist-style summary, referred to as a Memo. You can select the desired type by choosing the Prompt Type in the Settings. Both types of summaries can be manually edited to correct any errors."))
                }
                Section(header: Text(LocalizedStringKey("Policy"))) {
                    Text(LocalizedStringKey("Regarding cancellations and refunds, this app adheres to the policies of the Apple Store. Additionally, there is a usage cap for subscribers, limiting their monthly expenses to approximately twice the amount we pay OpenAI for using its API. If a subscriber exceeds this limit, they can make a one-time purchase of tokens to continue using the app."))
                    HStack {
                        let localizedString = NSLocalizedString("Terms of Use (EULA)", comment: "")
                        let parts = localizedString.components(separatedBy: "(EULA)")
                        Text(parts[0])
                        Text(LocalizedStringKey("(EULA)"))
                            .foregroundStyle(.blue)
                            .underline()
                            .onTapGesture {
                                if let url = URL(string: "https://www.apple.com/legal/macapps/stdeula/") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        Text(parts[1])
                    }
                }
            }
        }
        .navigationTitle("")
        .onAppear {
            loadNotice()
        }
    }
    
    private var getEula: AttributedString {
        var text = AttributedString("We follow the same Terms of Use (EULA) as Apple.")
        text[text.range(of: "Terms of Use (EULA)")!].underlineStyle = .single
        text[text.range(of: "Terms of Use (EULA)")!].link = URL(string: "https://www.apple.com/legal/macapps/stdeula/")!
        return text
    }
    
    private func loadNotice() {
        Task { @MainActor in
            if let fetchedNotice = try await Websocket.shared.getNotice() {
                print(fetchedNotice as Any)
                notice = fetchedNotice
            }
        }
    }
}

#Preview {
    HelpView()
}
