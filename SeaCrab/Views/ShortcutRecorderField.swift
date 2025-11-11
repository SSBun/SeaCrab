//
//  ShortcutRecorderField.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import SwiftUI
import AppKit
import Carbon

struct ShortcutRecorderField: NSViewRepresentable {
    @Binding var keyCode: Int?
    @Binding var modifiers: UInt?
    @Binding var isRecording: Bool
    let onShortcutChanged: () -> Void
    let onClear: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        
        let textField = ClickableTextField()
        textField.isEditable = false
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textField.alignment = .center
        textField.delegate = context.coordinator
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up click handler
        textField.onClick = {
            context.coordinator.startRecording()
        }
        
        // Create clear button
        let clearButton = NSButton()
        clearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear")
        clearButton.isBordered = false
        clearButton.bezelStyle = .inline
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.target = context.coordinator
        clearButton.action = #selector(Coordinator.clearShortcut)
        clearButton.contentTintColor = .secondaryLabelColor
        clearButton.toolTip = "Clear shortcut"
        
        containerView.addSubview(textField)
        containerView.addSubview(clearButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textField.topAnchor.constraint(equalTo: containerView.topAnchor),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            textField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -4),
            
            clearButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            clearButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 20),
            clearButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        context.coordinator.textField = textField
        context.coordinator.clearButton = clearButton
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let textField = context.coordinator.textField else { return }
        
        if isRecording {
            textField.stringValue = "Press shortcut..."
            textField.becomeFirstResponder()
            context.coordinator.startRecording()
        } else {
            textField.stringValue = shortcutDisplayString()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func shortcutDisplayString() -> String {
        guard let keyCode = keyCode, let modifiers = modifiers else {
            return "No shortcut"
        }
        
        var parts: [String] = []
        
        let flags = CGEventFlags(rawValue: CGEventFlags.RawValue(modifiers))
        
        if flags.contains(.maskControl) {
            parts.append("⌃")
        }
        if flags.contains(.maskAlternate) {
            parts.append("⌥")
        }
        if flags.contains(.maskShift) {
            parts.append("⇧")
        }
        if flags.contains(.maskCommand) {
            parts.append("⌘")
        }
        
        let keyChar = keyCodeToString(CGKeyCode(keyCode))
        parts.append(keyChar)
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ keyCode: CGKeyCode) -> String {
        let keyMap: [CGKeyCode: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
            31: "O", 32: "U", 34: "I", 35: "P",
            37: "L", 38: "J", 40: "K",
            45: "N", 46: "M",
            49: "Space"
        ]
        
        return keyMap[keyCode] ?? String(keyCode)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ShortcutRecorderField
        var eventMonitor: Any?
        weak var textField: NSTextField?
        weak var clearButton: NSButton?
        
        init(_ parent: ShortcutRecorderField) {
            self.parent = parent
        }
        
        @objc func clearShortcut() {
            parent.onClear()
        }
        
        func startRecording() {
            guard parent.isRecording else {
                parent.isRecording = true
                return
            }
            
            // Remove existing monitor if any
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
            
            // Add local event monitor for key down events
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                guard let self = self else { return event }
                
                if event.type == .keyDown {
                    let keyCode = Int(event.keyCode)
                    let modifierFlags = event.modifierFlags
                    
                    // Convert NSEvent.ModifierFlags to CGEventFlags
                    var cgModifiers = CGEventFlags()
                    if modifierFlags.contains(.control) {
                        cgModifiers.insert(.maskControl)
                    }
                    if modifierFlags.contains(.option) {
                        cgModifiers.insert(.maskAlternate)
                    }
                    if modifierFlags.contains(.shift) {
                        cgModifiers.insert(.maskShift)
                    }
                    if modifierFlags.contains(.command) {
                        cgModifiers.insert(.maskCommand)
                    }
                    
                    // Require at least one modifier
                    if !cgModifiers.isEmpty {
                        DispatchQueue.main.async {
                            self.parent.keyCode = keyCode
                            self.parent.modifiers = UInt(cgModifiers.rawValue)
                            self.stopRecording()
                            self.parent.onShortcutChanged()
                        }
                        return nil // Consume the event
                    }
                }
                
                return event
            }
        }
        
        func stopRecording() {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
            parent.isRecording = false
        }
        
        deinit {
            stopRecording()
        }
    }
}

// Custom NSTextField that handles clicks
class ClickableTextField: NSTextField {
    var onClick: (() -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

