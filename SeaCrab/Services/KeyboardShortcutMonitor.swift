//
//  KeyboardShortcutMonitor.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import Cocoa
import Carbon

@MainActor
class KeyboardShortcutMonitor: ObservableObject {
    nonisolated(unsafe) private var eventTap: CFMachPort?
    nonisolated(unsafe) private var runLoopSource: CFRunLoopSource?
    private let shortcutHandler: (RefinementCard) -> Void
    
    init(shortcutHandler: @escaping (RefinementCard) -> Void) {
        self.shortcutHandler = shortcutHandler
    }
    
    func startMonitoring() -> Bool {
        // Check for accessibility permissions
        guard AXIsProcessTrusted() else {
            requestAccessibilityPermissions()
            return false
        }
        
        // Create event tap for keyboard events
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                
                let monitor = Unmanaged<KeyboardShortcutMonitor>.fromOpaque(refcon).takeUnretainedValue()
                
                // Get all configured cards from settings
                let settings = AppSettings.shared
                let cards = settings.refinementCards
                
                // Check if current event matches any configured shortcut
                let flags = event.flags
                let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
                
                // Try to match the shortcut to any card
                for card in cards {
                    // Skip cards without shortcuts
                    guard let cardKeyCode = card.keyCode, let cardModifiers = card.modifiers else {
                        continue
                    }
                    
                    let expectedModifiers = CGEventFlags(rawValue: CGEventFlags.RawValue(cardModifiers))
                    
                    // Check if all expected modifiers are pressed and key code matches
                    var modifiersMatch = true
                    if expectedModifiers.contains(.maskControl) {
                        modifiersMatch = modifiersMatch && flags.contains(.maskControl)
                    }
                    if expectedModifiers.contains(.maskAlternate) {
                        modifiersMatch = modifiersMatch && flags.contains(.maskAlternate)
                    }
                    if expectedModifiers.contains(.maskShift) {
                        modifiersMatch = modifiersMatch && flags.contains(.maskShift)
                    }
                    if expectedModifiers.contains(.maskCommand) {
                        modifiersMatch = modifiersMatch && flags.contains(.maskCommand)
                    }
                    
                    if modifiersMatch && keyCode == cardKeyCode {
                        Task { @MainActor in
                            monitor.shortcutHandler(card)
                        }
                        // Consume the event
                        return nil
                    }
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }
        
        self.eventTap = eventTap
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        self.runLoopSource = runLoopSource
        
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        return true
    }
    
    func restartMonitoring() {
        stopMonitoring()
        _ = startMonitoring()
    }
    
    nonisolated func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
    
    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    deinit {
        stopMonitoring()
    }
}

