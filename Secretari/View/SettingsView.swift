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
    
    @State private var selectedLocale: RecognizerLocale = AppConstants.defaultSettings.selectedLocale
    @State private var promptType: Settings.PromptType = AppConstants.defaultSettings.promptType
    @State private var selectedPrompt: String = " "
    
    @State private var countDown = 0
    @State private var opacity = 1.0
    @State private var timer: Timer?
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Parameters")) {
                    HStack {
                        Text("Min audiable dB")
                        Spacer()
                        TextField(setting.audioSilentDB, text: $setting.audioSilentDB)
                            .frame(width: 80)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Prompt Type", selection: $promptType) {
                        ForEach(Settings.PromptType.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: promptType, { oldValue, newValue in
                        print(oldValue, newValue)
                        selectedPrompt = setting.prompt[promptType]![selectedLocale]!
                    })
                    
                    Picker("Language:", selection: $selectedLocale) {
                        ForEach(RecognizerLocale.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: selectedLocale) {
                        selectedPrompt = setting.prompt[promptType]![selectedLocale]!
                    }
                }
                Section(header: Text("advanced")) {
                    TextField(setting.wssURL, text: $setting.wssURL)
                    TextField(selectedPrompt, text: $selectedPrompt, axis: .vertical)
                        .lineLimit(.max)
                }
                .opacity(self.opacity)
                .onTapGesture {
                    self.countDown += 1
                    print(self.countDown)
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
        }
        .onAppear(perform: {
            guard !settings.isEmpty else { return }
            setting = settings[0]
            selectedLocale = setting.selectedLocale
            promptType = setting.promptType
            selectedPrompt = setting.prompt[promptType]![selectedLocale]!
        })
        .onDisappear(perform: {
            settings[0].promptType = promptType
            settings[0].selectedLocale = selectedLocale
            settings[0].prompt[promptType]![selectedLocale] = selectedPrompt
        })
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showAlert = true
                }) {
                    Text("Reset")
                }
            }
        }
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("Alert"), message: Text("All settings will be reset."), primaryButton: .cancel(), secondaryButton: .destructive(Text("Yes"), action: {
                settings[0].prompt = AppConstants.defaultSettings.prompt
                settings[0].selectedLocale = AppConstants.defaultSettings.selectedLocale
                settings[0].audioSilentDB = AppConstants.defaultSettings.audioSilentDB
                settings[0].wssURL = AppConstants.defaultSettings.wssURL
                settings[0].promptType = AppConstants.defaultSettings.promptType
                selectedLocale = settings[0].selectedLocale
                promptType = settings[0].promptType
                selectedPrompt = settings[0].prompt[promptType]![selectedLocale]!
            }))}
        )
    }
}

#Preview {
    let container = try! ModelContainer(for: Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return SettingsView()
        .modelContainer(container)
}
