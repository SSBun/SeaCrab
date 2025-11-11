//
//  TextRefinementService.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import Cocoa
import AppKit

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
                // Step 1: Get selected text via pasteboard
                guard let selectedText = await getSelectedText() else {
                    lastError = "No text selected"
                    loadingIndicator.hide()
                    isProcessing = false
                    return
                }
                
                // Step 2: Send to LLM for refinement using the card's prompt
                let refinedText = try await llmService.refineText(selectedText, prompt: card.prompt)
                
                // Step 3: Replace selected text with refined version
                await replaceSelectedText(with: refinedText)
                
            } catch {
                lastError = error.localizedDescription
            }
            
            // Hide loading indicator
            loadingIndicator.hide()
            isProcessing = false
        }
    }
    
    private func getSelectedText() async -> String? {
        // Save current pasteboard content
        let pasteboard = NSPasteboard.general
        _ = pasteboard.string(forType: .string)
        
        // Simulate Cmd+C to copy selected text
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Cmd Down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand
        
        // C Down
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cDown?.flags = .maskCommand
        
        // C Up
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cUp?.flags = .maskCommand
        
        // Cmd Up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        // Wait for pasteboard to update
        try? await Task.sleep(for: .milliseconds(100))
        
        let copiedText = pasteboard.string(forType: .string)
        
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

