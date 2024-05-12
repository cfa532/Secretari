//
//  SettingsView.swift
//  SummarySwiftData
//
//  Created by 超方 on 2024/4/17.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: Settings
    @State private var selectedPrompt = ""
    @State private var countDown = 0
    @State private var opacity = 1.0
    @State private var timer: Timer?
    @State private var showAlert = false
    
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
                    }
                    
                    Picker("Prompt Type", selection: $settings.promptType) {
                        ForEach(Settings.PromptType.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: settings.promptType) { oldValue, newValue in
                        selectedPrompt = settings.prompt[settings.promptType]![settings.selectedLocale]!
                    }
                    Picker("Language:", selection: $settings.selectedLocale) {
                        ForEach(RecognizerLocale.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: settings.selectedLocale) { oldValue, newValue in
                        selectedPrompt = settings.prompt[settings.promptType]![settings.selectedLocale]!
                    }
                }
                Section(header: Text("advanced")) {
                    TextField(settings.wssURL, text: $settings.wssURL)
                    TextField(selectedPrompt, text: $selectedPrompt, axis: .vertical)
                        .lineLimit(.max)
                }
                .onAppear(perform: {
                    selectedPrompt = settings.prompt[settings.promptType]![settings.selectedLocale]!
                })
                .onDisappear(perform: {
                    settings.prompt[settings.promptType]![settings.selectedLocale] = selectedPrompt
                    if let t = Double(settings.audioSilentDB) {
                        if t > -20 { settings.audioSilentDB = "-20" }
                        else if t < -80 {
                            settings.audioSilentDB = "-80"
                        }
                    } else {
                        settings.audioSilentDB = "-40"
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
                settings.wssURL = AppConstants.defaultSettings.wssURL
                settings.promptType = AppConstants.defaultSettings.promptType
                settings.llmModel = AppConstants.defaultSettings.llmModel
                settings.llmParams = AppConstants.defaultSettings.llmParams
            }))}
        )
    }
}

#Preview {
    let container = try! ModelContainer(for: Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return SettingsView()
        .modelContainer(container)
}
