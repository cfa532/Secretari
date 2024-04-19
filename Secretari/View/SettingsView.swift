//
//  SettingsView.swift
//  SummarySwiftData
//
//  Created by 超方 on 2024/4/17.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [AppSettings]
    @State private var setting: AppSettings  = AppSettings.defaultSettings {
        didSet {
            if let t = Int(setting.audioSilentDB) {
                if t > -20 { setting.audioSilentDB = "-20" }
                else if t < -80 {
                    setting.audioSilentDB = "-80"
                }
            } else {
                setting.audioSilentDB = "-40"
            }
        }
    }
    @State private var selectedLocale: RecognizerLocals = RecognizerLocals.Chinese
    
    var body: some View {
        NavigationStack {
            Form {
                VStack(alignment: .leading) {
                    Text("Prompt to AI:")
                        .font(.headline)
                    TextEditor(text: $setting.prompt)
                        .frame(height: 80, alignment: .topLeading)
                }
                VStack(alignment: .leading) {
                    Text("Webservice URL:")
                        .font(.headline)
                    TextField("URL", text: $setting.wssURL)
                }
                HStack{
                    Picker("Language to recognize:", selection: $selectedLocale) {
                        ForEach(RecognizerLocals.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }.font(.headline)
                }
                HStack {
                    Text("Audio thresh hold:")
                        .font(.headline)
                    TextField("Min Audio Level", text: $setting.audioSilentDB)
                }
            }
            .onAppear(perform: {
                guard !settings.isEmpty else { return }
                setting = settings[0]
                //                setting.speechLocale = "zh_CN"
                print(setting.speechLocale)
                selectedLocale = RecognizerLocals(rawValue: setting.speechLocale)!
            })
            .onDisappear(perform: {
                settings[0].speechLocale = selectedLocale.rawValue
            })
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    settings[0].prompt = AppSettings.defaultSettings.prompt
                    settings[0].speechLocale = AppSettings.defaultSettings.speechLocale
                    settings[0].audioSilentDB = AppSettings.defaultSettings.audioSilentDB
                    settings[0].wssURL = AppSettings.defaultSettings.wssURL
                    selectedLocale = RecognizerLocals.Chinese
                }) {
                    Text("Reset settings").padding(5)
                }
                .foregroundColor(.black)
                .background(Color(white: 0.8))
                .cornerRadius(5.0)
                .shadow(color:.gray, radius: 2, x: 2, y: 2)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: AppSettings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return SettingsView()
        .modelContainer(container)
}
