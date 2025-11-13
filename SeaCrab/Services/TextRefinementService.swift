//
//  TextRefinementService.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import Cocoa
import AppKit
import ApplicationServices

@MainActor
class TextRefinementService: ObservableObject {
    private let llmService = LLMService()
    private let loadingIndicator = LoadingIndicatorWindow()
    @Published var isProcessing = false
    @Published var lastError: String?
    
    func refineSelectedText(using card: RefinementCard) {
        guard !isProcessing else { return }
        
        Task {
            isProcessing = true
            lastError = nil
            
            // Show loading indicator near cursor
            loadingIndicator.show()
            
            do {
                // Step 1: Get selected text (prefer Accessibility API, fallback to clipboard)
                let textResult = await getSelectedText()
                guard let (selectedText, element, hasSelection) = textResult else {
                    lastError = "No text selected"
                    loadingIndicator.hide()
                    isProcessing = false
                    return
                }
                
                // Step 2: Send to LLM for refinement using the card's prompt
                let refinedText = try await llmService.refineText(selectedText, prompt: card.prompt)
                
                // Step 3: Replace text with refined version
                // If we have element AND no selection, set value directly (no selection highlight)
                // If text was selected, use clipboard/paste to preserve selection behavior
                if let element = element, !hasSelection {
                    // No selection - replace entire field directly (no visual selection)
                    await replaceTextViaAccessibility(element: element, text: refinedText)
                } else {
                    // Has selection or no element - use clipboard/paste method
                    await replaceSelectedText(with: refinedText)
                }
                
            } catch {
                lastError = error.localizedDescription
            }
            
            // Hide loading indicator
            loadingIndicator.hide()
            isProcessing = false
        }
    }
    
    /// Get selected text and return element info for replacement
    /// Returns: (text, element, hasSelection) tuple
    private func getSelectedText() async -> (String, AXUIElement?, Bool)? {
        // First, try to get text via Accessibility API (more reliable, no clipboard interference)
        let accessibilityResult = getTextViaAccessibility()
        if let (text, hasSelection, element) = accessibilityResult {
            // Return text with element and selection info
            return (text, element, hasSelection)
        }
        
        // Fallback to clipboard method if Accessibility API fails
        if let text = await getSelectedTextViaClipboard() {
            return (text, nil, false) // No element available, will use clipboard/paste method
        }
        
        return nil
    }
    
    /// Get text using Accessibility API - preferred method
    /// Returns: (text, hasSelection, element) tuple where:
    ///   - text: The text content
    ///   - hasSelection: Whether text was actually selected
    ///   - element: The AXUIElement for setting selection if needed
    private func getTextViaAccessibility() -> (String, Bool, AXUIElement?)? {
        // Get the system-wide accessibility element
        let systemWideElement = AXUIElementCreateSystemWide()
        
        // Get the currently focused application
        var focusedApp: AnyObject?
        let appResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        
        guard appResult == .success,
              let appElement = focusedApp as! AXUIElement? else {
            return nil
        }
        
        // Get the focused UI element within the app
        var focusedElement: AnyObject?
        let focusedResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        guard focusedResult == .success,
              let element = focusedElement as! AXUIElement? else {
            return nil
        }
        
        // Try to get selected text first
        var selectedText: AnyObject?
        let selectedTextResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        
        if selectedTextResult == .success,
           let text = selectedText as? String,
           !text.isEmpty {
            return (text, true, element) // Text was actually selected
        }
        
        // If no selection, get the full text value (for text fields)
        var value: AnyObject?
        let valueResult = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &value
        )
        
        if valueResult == .success,
           let text = value as? String,
           !text.isEmpty {
            return (text, false, element) // Got full text but nothing was selected
        }
        
        // Try to get text content from text area elements
        var textContent: AnyObject?
        let textContentResult = AXUIElementCopyAttributeValue(
            element,
            kAXTextAttribute as CFString,
            &textContent
        )
        
        if textContentResult == .success,
           let text = textContent as? String,
           !text.isEmpty {
            return (text, false, element) // Got text content but nothing was selected
        }
        
        return nil
    }
    
    /// Replace text directly using Accessibility API (no selection highlight, no clipboard)
    private func replaceTextViaAccessibility(element: AXUIElement, text: String) async {
        // Directly set the value attribute
        let setResult = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            text as CFString
        )
        
        // If direct setting fails, fallback to clipboard/paste method
        guard setResult == .success else {
            await replaceSelectedText(with: text)
            return
        }
        
        // Immediately deselect by setting cursor to end (location: text.count, length: 0)
        // This removes any selection highlight that might have appeared
        var cursorRange = CFRange(location: text.count, length: 0)
        if let cursorRangeValue = AXValueCreate(.cfRange, &cursorRange) {
            AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextRangeAttribute as CFString,
                cursorRangeValue
            )
        }
    }
    
    /// Fallback method using clipboard (Cmd+C) - used when Accessibility API fails
    private func getSelectedTextViaClipboard() async -> String? {
        let pasteboard = NSPasteboard.general
        let originalPasteboardContent = pasteboard.string(forType: .string)
        
        // First, try to get selected text by simulating Cmd+C
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Simulate Cmd+C to copy selected text
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand
        
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cDown?.flags = .maskCommand
        
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cUp?.flags = .maskCommand
        
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        // Wait for pasteboard to update
        try? await Task.sleep(for: .milliseconds(100))
        
        var copiedText = pasteboard.string(forType: .string)
        
        // If no text was selected (pasteboard unchanged or empty), select all text in focused field
        if copiedText == originalPasteboardContent || (copiedText?.isEmpty ?? true) {
            // Simulate Cmd+A to select all text in the focused text field
            let cmdADown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            cmdADown?.flags = .maskCommand
            
            let aDown = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: true)
            aDown?.flags = .maskCommand
            
            let aUp = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: false)
            aUp?.flags = .maskCommand
            
            let cmdAUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
            
            cmdADown?.post(tap: .cghidEventTap)
            aDown?.post(tap: .cghidEventTap)
            aUp?.post(tap: .cghidEventTap)
            cmdAUp?.post(tap: .cghidEventTap)
            
            // Wait for selection to complete
            try? await Task.sleep(for: .milliseconds(100))
            
            // Now copy the selected text
            let cmdDown2 = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            cmdDown2?.flags = .maskCommand
            
            let cDown2 = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
            cDown2?.flags = .maskCommand
            
            let cUp2 = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
            cUp2?.flags = .maskCommand
            
            let cmdUp2 = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
            
            cmdDown2?.post(tap: .cghidEventTap)
            cDown2?.post(tap: .cghidEventTap)
            cUp2?.post(tap: .cghidEventTap)
            cmdUp2?.post(tap: .cghidEventTap)
            
            // Wait for pasteboard to update
            try? await Task.sleep(for: .milliseconds(100))
            
            copiedText = pasteboard.string(forType: .string)
        }
        
        return copiedText
    }
    
    private func replaceSelectedText(with text: String) async {
        // Put refined text on pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Simulate Cmd+V to paste
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Cmd Down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand
        
        // V Down
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        
        // V Up
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        
        // Cmd Up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
}

