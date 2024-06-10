//
//  SettingsView.swift
//  SummarySwiftData
//
//  Created by 超方 on 2024/4/17.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var settings = SettingsManager.shared.getSettings()
    @State private var selectedPrompt =  SettingsManager.shared.getSettings().prompt[SettingsManager.shared.getSettings().promptType]![SettingsManager.shared.getSettings().selectedLocale]
    @State private var countDown = 0
    @State private var opacity = 1.0
    @State private var timer: Timer?
    @State private var showAlert = false
    @State private var changed = false
        
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Parameters")) {
                    HStack {
                        Text("Min Audible (dB)")
                        Spacer()
                        TextField(settings.audioSilentDB, text: Binding<String>(
                            get: {settings.audioSilentDB}, set: { changed=true;
                                if let t = Double($0) {
                                    if t > -20 { settings.audioSilentDB = "-20" }
                                    else if t < -80 {
                                        settings.audioSilentDB = "-80"
                                    }
                                } else {
                                    settings.audioSilentDB = "-40"
                                }
                            }))
                            .frame(width: 80)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Prompt Type", selection: $settings.promptType) {
                        
                        // if the account balance<0.1, only gpt-3.5 is allowed, therefore NO memo type here.
//                        ForEach(Settings.PromptType.allowedCases(lowBalance: allowedPromptType()), id:\.self) { option in
                        ForEach(Settings.PromptType.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: settings.promptType) { oldValue, newValue in
                        selectedPrompt = settings.prompt[settings.promptType]![settings.selectedLocale]!
                        changed = true
                    }
                    
                    Picker("Language:", selection: $settings.selectedLocale) {
                        ForEach(RecognizerLocale.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: settings.selectedLocale) { oldValue, newValue in
                        selectedPrompt = settings.prompt[settings.promptType]![settings.selectedLocale]!
                        changed = true
                    }
                }
                Section(header: Text("advanced")) {
                    TextField(settings.serverURL, text: $settings.serverURL)
                        .onChange(of: settings.serverURL) { oldValue, newValue in
                            if (oldValue != newValue) {
                                changed = true
                            }
                        }
                    TextField(selectedPrompt ?? "", text: Binding<String> (
                        get: {settings.prompt[settings.promptType]![settings.selectedLocale]!},
                        set: {settings.prompt[settings.promptType]![settings.selectedLocale] = $0; changed=true}), axis: .vertical)
                        .lineLimit(20)
                }
                .onAppear(perform: {
                    settings = SettingsManager.shared.getSettings()
                })
                .onDisappear(perform: {
                    if (changed) {
                        SettingsManager.shared.updateSettings(settings)
                        changed = false
                    }
                })
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
                
                settings.prompt = AppConstants.defaultSettings.prompt
                settings.selectedLocale = AppConstants.defaultSettings.selectedLocale
                settings.audioSilentDB = AppConstants.defaultSettings.audioSilentDB
                settings.serverURL = AppConstants.defaultSettings.serverURL
                settings.promptType = AppConstants.defaultSettings.promptType
                settings.llmModel = AppConstants.defaultSettings.llmModel
                settings.llmParams = AppConstants.defaultSettings.llmParams
            }))}
        )
    }
    
    private func allowedPromptType() -> Bool {
        if let user = UserManager.shared.currentUser, user.dollar_balance <= 0.1 {
            // non-subscriber has not enough balance for gpt-4
            return true
        }
        return false
    }
}

#Preview {
    SettingsView()
}
