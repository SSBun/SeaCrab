//
//  SeaCrabApp.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import SwiftUI

@main
struct SeaCrabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var keyboardMonitor: KeyboardShortcutMonitor?
    private let textRefinementService = TextRefinementService()
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon and main window
        NSApp.setActivationPolicy(.accessory)
        
        // Create status bar item
        setupStatusBar()
        
        // Setup keyboard shortcut monitoring
        setupKeyboardMonitoring()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use app icon for menu bar
            if let appIcon = NSImage(named: "AppIcon") {
                // Resize to menu bar size (18x18 for standard, 36x36 for retina)
                appIcon.size = NSSize(width: 18, height: 18)
                button.image = appIcon
            } else {
                // Fallback to SF Symbol if app icon not found
                button.image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "SeaCrab")
            }
        }
        
        let menu = NSMenu()
        
        let statusMenuItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit SeaCrab", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        
        // Update status based on service state
        Task {
            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
                if textRefinementService.isProcessing {
                    statusMenuItem.title = "Processing..."
                } else if let error = textRefinementService.lastError {
                    statusMenuItem.title = "Error: \(error)"
                } else {
                    statusMenuItem.title = "Ready"
                }
            }
        }
    }
    
    private func setupKeyboardMonitoring() {
        keyboardMonitor = KeyboardShortcutMonitor { [weak self] card in
            self?.handleShortcut(card: card)
        }
        
        if keyboardMonitor?.startMonitoring() == false {
            // Failed to start - likely no accessibility permissions
            showAccessibilityAlert()
        }
    }
    
    @objc private func openSettings() {
        // If settings window doesn't exist, create it
        if settingsWindow == nil {
            let settingsView = SettingsView { [weak self] in
                // Restart keyboard monitoring when shortcut changes
                self?.keyboardMonitor?.restartMonitoring()
            }
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "SeaCrab Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.center()
            window.setFrameAutosaveName("SeaCrabSettings")
            
            settingsWindow = window
        }
        
        // Show and focus the window
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func handleShortcut(card: RefinementCard) {
        textRefinementService.refineSelectedText(using: card)
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permissions Required"
        alert.informativeText = "SeaCrab needs accessibility permissions to monitor keyboard shortcuts. Please grant permissions in System Settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
}

