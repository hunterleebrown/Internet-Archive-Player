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

    @State var showAbout: Bool = false
    @State var showDisclaimer: Bool = false
    @State var showPrivacy: Bool = false

    @State private var playerSkin: PlayerControlsSkin = .classic

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // App Info Section
                    VStack(spacing: 16) {
                        Image("IA-Music-fairy-1024")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.top, 8)
                        
                        VStack(spacing: 4) {
                            Text("Internet Archive Player")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Version \(viewModel.versionString)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("© 2025 Hunter Lee Brown")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    )
                    
                    // Player Skin Section
                    SettingCard(title: "Player Skin") {
                        VStack(alignment: .leading, spacing: 12) {

                            HStack(spacing: 20) {
                                Spacer()

                                PlayerSkinButton(
                                    skin: .classic,
                                    imageName: "classic",
                                    label: "Classic",
                                    selectedSkin: $playerSkin,
                                    onSelect: { skin in
                                        iaPlayer.playerSkin = skin
                                    }
                                )
                                
                                Spacer()
                                
                                PlayerSkinButton(
                                    skin: .winAmp,
                                    imageName: "winamp",
                                    label: "Winamp",
                                    selectedSkin: $playerSkin,
                                    onSelect: { skin in
                                        iaPlayer.playerSkin = skin
                                    }
                                )

                                Spacer()
                                
                            }
                        }
                    }
                    
                    // Legal Section
                    SettingCard(title: "Legal") {
                        VStack(spacing: 12) {
                            ExpandableSection(
                                title: "About",
                                isExpanded: $showAbout,
                                content: "This app is an independent client for accessing content from the Internet Archive. All music and content is provided by archive.org. This app and its design are © 2025 Hunter Lee Brown."
                            )
                            
                            Divider()
                                .padding(.horizontal, -16)
                            
                            ExpandableSection(
                                title: "Disclaimer",
                                isExpanded: $showDisclaimer,
                                content: viewModel.disclaimerText
                            )
                            
                            Divider()
                                .padding(.horizontal, -16)
                            
                            ExpandableSection(
                                title: "Privacy Policy",
                                isExpanded: $showPrivacy,
                                content: viewModel.privacyText
                            )
                        }
                    }
                    
                    // Debug Section
                    SettingCard(title: "Developer") {
                        NavigationLink(destination: DebugView()) {
                            HStack {
                                Text("Debug Tools")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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

// MARK: - Supporting Views

struct SettingCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

struct ExpandableSection: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                }
            }
            
            if isExpanded {
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            }
        }
    }
}

struct PlayerSkinButton: View {
    let skin: PlayerControlsSkin
    let imageName: String
    let label: String
    @Binding var selectedSkin: PlayerControlsSkin
    let onSelect: (PlayerControlsSkin) -> Void
    
    private var isSelected: Bool {
        selectedSkin == skin
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedSkin = skin
                    onSelect(skin)
                }
            } label: {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.fairyRed : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            
            Text(label)
                .font(.caption)
                .foregroundColor(isSelected ? .fairyRed : .secondary)
                .fontWeight(isSelected ? .semibold : .regular)
        }
    }
}

// MARK: - View Model

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
                // Debug: List all txt files in bundle
                if let resourcePath = Bundle.main.resourcePath {
                    let fileManager = FileManager.default
                    if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                        let txtFiles = files.filter { $0.hasSuffix(".txt") }
                    }
                }
                return fallback
            }
            
            // Try to read the file
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                return content
            } catch {
                return fallback
            }
        }
    }
}
