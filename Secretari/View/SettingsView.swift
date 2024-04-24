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
                        ForEach(RecognizerLocals.allCases, id:\.self) { option in
                            Text(String(describing: option))
                        }
                    }
                }
                Section(header: Text("advanced")) {
                    TextField(setting.prompt, text: $setting.prompt, axis: .vertical)
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
                print(setting.speechLocale)
                selectedLocale = RecognizerLocals(rawValue: setting.speechLocale)!
            })
            .onDisappear(perform: {
                settings[0].speechLocale = selectedLocale.rawValue
            })
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    settings[0].prompt = AppSettings.defaultSettings.prompt
                    settings[0].speechLocale = AppSettings.defaultSettings.speechLocale
                    settings[0].audioSilentDB = AppSettings.defaultSettings.audioSilentDB
                    settings[0].wssURL = AppSettings.defaultSettings.wssURL
                    
                    let lc = NSLocale.current.language.languageCode?.identifier
                    switch lc {
                    case "en":
                        selectedLocale = RecognizerLocals.English
                    case "ja":
                        selectedLocale = RecognizerLocals.Japanese
                    default:
                        selectedLocale = RecognizerLocals.Chinese
                    }
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
