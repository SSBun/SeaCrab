//
//  RefinementCard.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import Foundation
import Carbon

struct RefinementCard: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var prompt: String
    var keyCode: Int?
    var modifiers: UInt?
    var canRemoved: Bool = true
    
    init(
        id: UUID = UUID(),
        name: String,
        prompt: String,
        keyCode: Int? = 15,
        modifiers: UInt? = UInt(CGEventFlags.maskControl.rawValue),
        canRemoved: Bool = true
    ) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.canRemoved = canRemoved
    }
    
    func shortcutDisplayString() -> String {
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
        
        // Convert key code to character
        let keyChar = keyCodeToString(CGKeyCode(keyCode))
        parts.append(keyChar)
        
        return parts.joined()
    }
    
    var hasShortcut: Bool {
        return keyCode != nil && modifiers != nil
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
    
    static var defaultCard: RefinementCard {
        RefinementCard(
            name: "General Refinement",
            prompt: BuiltInPrompt.grammarAndSpelling.prompt,
            keyCode: 15, // R key
            modifiers: UInt(CGEventFlags.maskControl.rawValue),
            canRemoved: false
        )
    }
}

