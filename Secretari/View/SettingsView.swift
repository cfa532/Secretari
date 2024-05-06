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
    @State private var summaryOn: Bool = true
    @State private var selectedLocale: RecognizerLocale = AppConstants.defaultSettings.selectedLocale
    @State private var selectedPrompt: String = AppConstants.defaultSettings.prompt[AppConstants.defaultSettings.selectedLocale]!
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
                    Picker("Language:", selection: $selectedLocale) {
                        ForEach(RecognizerLocale.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: selectedLocale) {
                        guard let p = setting.prompt[selectedLocale] else {return}
                        selectedPrompt = p
                    }
                    Toggle(summaryOn ? "Summary" : "Memo", isOn: $summaryOn)
                        .onChange(of: summaryOn, { oldValue, newValue in
                            settings[0].outputType = newValue ? .summary : .memo
                        })
                }
                Section(header: Text("advanced")) {
                    TextField(selectedPrompt, text: $selectedPrompt, axis: .vertical)
                        .lineLimit(2...8)
                    TextField(setting.wssURL, text: $setting.wssURL)
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
            .onAppear(perform: {
                guard !settings.isEmpty else { return }
                setting = settings[0]
                selectedLocale = setting.selectedLocale
                selectedPrompt = setting.prompt[selectedLocale] ?? AppConstants.defaultPrompt[.English]!
                summaryOn = setting.outputType == .summary ? true : false
            })
            .onDisappear(perform: {
                settings[0].selectedLocale = selectedLocale
                settings[0].prompt[selectedLocale] = selectedPrompt
            })
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
                settings[0].prompt = AppConstants.defaultSettings.prompt
                settings[0].selectedLocale = AppConstants.defaultSettings.selectedLocale
                settings[0].audioSilentDB = AppConstants.defaultSettings.audioSilentDB
                settings[0].wssURL = AppConstants.defaultSettings.wssURL
                selectedLocale = settings[0].selectedLocale })
            )}
        )
    }
}

#Preview {
    let container = try! ModelContainer(for: Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return SettingsView()
        .modelContainer(container)
}
