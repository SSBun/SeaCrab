//
//  RefinementCardView.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import SwiftUI

struct RefinementCardView: View {
    @Binding var card: RefinementCard
    let onDelete: () -> Void
    let onShortcutChanged: () -> Void
    @State private var isRecordingShortcut = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and delete button
            HStack {
                TextField("Card Name", text: $card.name)
                    .textFieldStyle(.plain)
                    .font(.headline)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .disabled(!card.canRemoved)
                .buttonStyle(.plain)
                .help("Delete this card")
            }
            
            Divider()
            
            // Keyboard shortcut
            VStack(alignment: .leading, spacing: 6) {
                Text("Keyboard Shortcut")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    ShortcutRecorderField(
                        keyCode: $card.keyCode,
                        modifiers: $card.modifiers,
                        isRecording: $isRecordingShortcut,
                        onShortcutChanged: onShortcutChanged,
                        onClear: {
                            // Remove the shortcut
                            card.keyCode = nil
                            card.modifiers = nil
                            onShortcutChanged()
                        }
                    )
                    .frame(minWidth: 150, maxWidth: 220)
                    .frame(height: 28)
                    
                    Button(isRecordingShortcut ? "Cancel" : "Record") {
                        isRecordingShortcut.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // Prompt editor
            VStack(alignment: .leading, spacing: 6) {
                Text("Refinement Prompt")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $card.prompt)
                    .frame(height: 120)
                    .font(.system(.caption, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

