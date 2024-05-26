//
//  SettingsView.swift
//  SummarySwiftData
//
//  Created by 超方 on 2024/4/17.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var selectedPrompt = ""
    @State private var countDown = 0
    @State private var opacity = 1.0
    @State private var timer: Timer?
    @State private var showAlert = false
    @State private var changed = false
    
    @Binding var settings: Settings
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Parameters")) {
                    HStack {
                        Text("Min Audible (dB)")
                        Spacer()
                        TextField(settings.audioSilentDB, text: $settings.audioSilentDB)
                            .frame(width: 80)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: settings.audioSilentDB) { oldValue, newValue in
                                if (oldValue != newValue) {
                                    changed = true
                                }
                            }
                    }
                    
                    Picker("Prompt Type", selection: $settings.promptType) {
                        ForEach(Settings.PromptType.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: settings.promptType) { oldValue, newValue in
                        print(oldValue, newValue)
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
                        if (oldValue != newValue) {
                            print(oldValue, newValue)
                            changed = true
                        }
                    }
                }
                Section(header: Text("advanced")) {
                    TextField(settings.serverURL, text: $settings.serverURL)
                        .onChange(of: settings.serverURL) { oldValue, newValue in
                            if (oldValue != newValue) {
                                changed = true
                            }
                        }
                    TextField(selectedPrompt, text: $selectedPrompt, axis: .vertical)
                        .lineLimit(.max)
                        .onChange(of: selectedPrompt) { oldValue, newValue in
                            if (oldValue != newValue) {
                                changed = true
                            }
                        }
                }
                .onAppear(perform: {
                    selectedPrompt = settings.prompt[settings.promptType]![settings.selectedLocale]!
                    print(settings)
                })
                .onDisappear(perform: {
                    if (changed) {
                        settings.prompt[settings.promptType]![settings.selectedLocale] = selectedPrompt
                        if let t = Double(settings.audioSilentDB) {
                            if t > -20 { settings.audioSilentDB = "-20" }
                            else if t < -80 {
                                settings.audioSilentDB = "-80"
                            }
                        } else {
                            settings.audioSilentDB = "-40"
                        }
                        SettingsManager.shared.updateSettings(settings)
                        changed = false
                    }
                    print(settings)
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
}

#Preview {
    return SettingsView(settings: .constant(AppConstants.defaultSettings))
}
