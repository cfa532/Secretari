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
    @Query private var settings: [Settings]
    @State private var setting: Settings  = AppConstants.defaultSettings {
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
    @State private var selectedLocale: RecognizerLocale = AppConstants.defaultSettings.speechLocale
    @State private var selectedPrompt: String = AppConstants.defaultSettings.prompt[AppConstants.defaultSettings.speechLocale]!
    @State private var countDown = 0
    @State private var opacity = 1.0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Parameters")) {
                    HStack {
                        Text("Recording DB Level:")
                        Spacer()
                        TextField(setting.audioSilentDB, text: $setting.audioSilentDB)
                            .frame(width: 80)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Language:", selection: $selectedLocale) {
                        ForEach(RecognizerLocale.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: selectedLocale) {
                        selectedPrompt = setting.prompt[selectedLocale]!
                    }
                }
                Section(header: Text("advanced")) {
                    TextField("", text: $selectedPrompt, axis: .vertical)
                        .lineLimit(2...8)
                    TextField(setting.wssURL, text: $setting.wssURL)
                }
                .opacity(self.opacity)
                .onTapGesture {
                    self.countDown += 1
                    if timer==nil, self.opacity>0 {
                        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: {  _ in
                            if self.countDown > 5 {
                                self.opacity = 1.0
                                self.countDown = 0
                                timer?.invalidate()
                            }
                        })
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: {
                guard !settings.isEmpty else { return }
                setting = settings[0]
                //                setting.speechLocale = "zh_CN"
                //                print("seleted lang", setting.speechLocale)
                selectedLocale = setting.speechLocale
                selectedPrompt = setting.prompt[selectedLocale]!
            })
            .onDisappear(perform: {
                settings[0].speechLocale = selectedLocale
                settings[0].prompt[selectedLocale] = selectedPrompt
            })
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    settings[0].prompt = AppConstants.defaultSettings.prompt
                    settings[0].speechLocale = AppConstants.defaultSettings.speechLocale
                    settings[0].audioSilentDB = AppConstants.defaultSettings.audioSilentDB
                    settings[0].wssURL = AppConstants.defaultSettings.wssURL
                    selectedLocale = settings[0].speechLocale
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
    let container = try! ModelContainer(for: Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return SettingsView()
        .modelContainer(container)
}
