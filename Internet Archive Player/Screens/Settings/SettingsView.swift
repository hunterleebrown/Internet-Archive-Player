//
//  SettingsView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/29/25.
//

import SwiftUI
import iaAPI

struct SettingsView: View {
    @EnvironmentObject var iaPlayer: Player
    @StateObject private var viewModel = ViewModel()

    @State var showDisclaimer: Bool = false
    @State var showPrivacy: Bool = false

    @State private var playerSkin: PlayerControlsSkin = .classic

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Version section
                    HStack {
                        Text("Version: ")
                            .foregroundColor(.fairyRed)
                        Text(viewModel.versionString)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    HStack{
                        Text("Player skin: ")
                            .foregroundColor(.fairyRed)
                        Picker("Player Skin", selection: $playerSkin) {
                            ForEach(PlayerControlsSkin.allCases, id: \.self) {
                                Text($0.rawValue.capitalized)
                            }
                            .onChange(of: playerSkin) {
                                withAnimation {
                                    iaPlayer.playerSkin = playerSkin
                                }
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // Disclaimer section
                    VStack(alignment: .leading, spacing: 8) {

                        Button {
                            withAnimation {
                                showDisclaimer.toggle()
                            }
                        } label: {
                            Text("Disclaimer")
                                .foregroundColor(.fairyRed)
                        }

                        if showDisclaimer {
                            Text(viewModel.disclaimerText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Divider()

                    // Privacy Policy section
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation {
                                showPrivacy.toggle()
                            }
                        } label: {
                            Text("IA Player Privacy Policy")
                                .foregroundColor(.fairyRed)
                        }

                        if showPrivacy {
                            Text(viewModel.privacyText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Divider()

                    NavigationLink(destination: DebugView()) {
                        Text("Debug")
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .avoidPlayer()
            .task{
                if let skin = iaPlayer.playerSkin {
                    playerSkin = skin
                }
                viewModel.loadDisclaimer()
                viewModel.loadPrivacyText()
            }

        }
    }
}

extension SettingsView {
    @MainActor
    class ViewModel: ObservableObject {
        @Published var disclaimerText: String = ""
        @Published var privacyText: String = ""
        @Published var versionString: String = ""
        
        init() {
            loadVersionInfo()
        }

        func loadDisclaimer() {
            disclaimerText = loadTextFile(named: "Disclaimer", fallback: "Disclaimer text not available.")
        }

        func loadPrivacyText() {
            privacyText = loadTextFile(named: "Privacy", fallback: "Privacy text not available.")
        }
        
        private func loadVersionInfo() {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
            versionString = "\(version) (\(build))"
        }
        
        private func loadTextFile(named name: String, fallback: String) -> String {
            // First, let's try to find the file
            guard let url = Bundle.main.url(forResource: name, withExtension: "txt") else {
                print("❌ Could not find \(name).txt in bundle")
                print("Bundle path: \(Bundle.main.bundlePath)")
                
                // Debug: List all txt files in bundle
                if let resourcePath = Bundle.main.resourcePath {
                    let fileManager = FileManager.default
                    if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                        let txtFiles = files.filter { $0.hasSuffix(".txt") }
                        print("📁 Found .txt files in bundle: \(txtFiles)")
                    }
                }
                return fallback
            }
            
            // Try to read the file
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                print("✅ Successfully loaded \(name).txt")
                return content
            } catch {
                print("❌ Error reading \(name).txt: \(error.localizedDescription)")
                return fallback
            }
        }
    }
}
