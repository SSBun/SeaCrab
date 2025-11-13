//
//  SettingsView.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable var settings = AppSettings.shared
    @State private var isTestingConnection = false
    @State private var testResult: String?
    @State private var showSavedIndicator = false
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var onShortcutChanged: (() -> Void)?
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Base URL", text: $settings.baseURL)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: settings.baseURL) { _, _ in showAutoSaveIndicator() }
                    
                    Text("Full URL with https:// prefix (e.g., https://api.openai.com)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                SecureField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: settings.apiKey) { _, _ in showAutoSaveIndicator() }
                
                TextField("Model", text: $settings.model)
                    .textFieldStyle(.roundedBorder)
                    .help("Model name (e.g., gpt-4o-mini, gemini-2.5-flash)")
                    .onChange(of: settings.model) { _, _ in showAutoSaveIndicator() }
                
                HStack {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTestingConnection)
                    
                    if isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                
                if let result = testResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(result.hasPrefix("✅") ? .green : .red)
                        .textSelection(.enabled)
                }
            } header: {
                HStack {
                    Text("API Configuration")
                    Spacer()
                    if showSavedIndicator {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Saved")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach($settings.refinementCards) { $card in
                        RefinementCardView(
                            card: $card,
                            onDelete: {
                                if settings.refinementCards.count > 1 {
                                    settings.removeCard(card)
                                    onShortcutChanged?()
                                    showAutoSaveIndicator()
                                }
                            },
                            onShortcutChanged: {
                                settings.updateCard(card)
                                onShortcutChanged?()
                                showAutoSaveIndicator()
                            }
                        )
                        .onChange(of: card) { _, newValue in
                            settings.updateCard(newValue)
                            showAutoSaveIndicator()
                        }
                    }
                    
                    Button {
                        addNewCard()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Refinement Card")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Text("Each card combines a prompt with a keyboard shortcut. Create multiple cards for different refinement styles.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Refinement Cards")
            }
            
            Section("General") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: settings.launchAtLogin) { _, _ in showAutoSaveIndicator() }
                
                Text("Automatically start SeaCrab when you log in to your Mac")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Backup & Restore") {
                HStack(spacing: 12) {
                    Button {
                        exportConfiguration()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Configuration")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        importConfiguration()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Configuration")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                if showExportSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Configuration exported successfully")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .transition(.opacity)
                }
                
                if showImportSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Configuration imported successfully")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .transition(.opacity)
                }
                
                if showImportError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(importErrorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .transition(.opacity)
                }
                
                Text("Export your API settings and refinement cards to a JSON file for backup, or import from a previously exported file to restore settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Accessibility") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: AXIsProcessTrusted() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(AXIsProcessTrusted() ? .green : .orange)
                        Text(AXIsProcessTrusted() ? "Accessibility access granted" : "Accessibility access required")
                            .font(.subheadline)
                    }
                    
                    if !AXIsProcessTrusted() {
                        Button("Open System Settings") {
                            openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Text("Grant accessibility permissions to enable global keyboard shortcuts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 600)
        .navigationTitle("SeaCrab Settings")
    }
    
    private func testConnection() {
        // Validate inputs before testing
        let baseURL = settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !baseURL.isEmpty else {
            testResult = "❌ Base URL is required"
            return
        }
        
        guard !apiKey.isEmpty else {
            testResult = "❌ API Key is required"
            return
        }
        
        // Validate URL format - check if it's a valid URL
        if !baseURL.hasPrefix("http://") && !baseURL.hasPrefix("https://") {
            testResult = "❌ Base URL must start with http:// or https://"
            return
        }
        
        isTestingConnection = true
        testResult = nil
        
        Task {
            let service = LLMService()
            do {
                let result = try await service.testConnection()
                await MainActor.run {
                    testResult = result
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ Connection failed: \(error.localizedDescription)"
                    isTestingConnection = false
                }
            }
        }
    }
    
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func showAutoSaveIndicator() {
        withAnimation {
            showSavedIndicator = true
        }
        
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showSavedIndicator = false
            }
        }
    }
    
    private func addNewCard() {
        let newCard = RefinementCard(
            name: "New Refinement",
            prompt: "Enter your refinement prompt here...",
            keyCode: 15, // R key
            modifiers: UInt(CGEventFlags.maskControl.rawValue | CGEventFlags.maskShift.rawValue) // Control + Shift
        )
        settings.addCard(newCard)
        onShortcutChanged?()
        showAutoSaveIndicator()
    }
    
    private func exportConfiguration() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "SeaCrab-Configuration.json"
        savePanel.title = "Export SeaCrab Configuration"
        savePanel.prompt = "Export"
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            
            do {
                let configData = try settings.exportConfiguration()
                try configData.write(to: url)
                
                DispatchQueue.main.async {
                    showExportSuccess = true
                    showAutoSaveIndicator()
                    
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        withAnimation {
                            showExportSuccess = false
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    importErrorMessage = "Failed to export: \(error.localizedDescription)"
                    showImportError = true
                    
                    Task {
                        try? await Task.sleep(for: .seconds(5))
                        withAnimation {
                            showImportError = false
                        }
                    }
                }
            }
        }
    }
    
    private func importConfiguration() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Import SeaCrab Configuration"
        openPanel.prompt = "Import"
        
        openPanel.begin { response in
            guard response == .OK, let url = openPanel.url else { return }
            
            do {
                let configData = try Data(contentsOf: url)
                try settings.importConfiguration(from: configData)
                
                DispatchQueue.main.async {
                    showImportSuccess = true
                    showAutoSaveIndicator()
                    onShortcutChanged?()
                    
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        withAnimation {
                            showImportSuccess = false
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    importErrorMessage = "Failed to import: \(error.localizedDescription)"
                    showImportError = true
                    
                    Task {
                        try? await Task.sleep(for: .seconds(5))
                        withAnimation {
                            showImportError = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}

