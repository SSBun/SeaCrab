//
//  LoadingIndicatorWindow.swift
//  SeaCrab
//
//  Created by caishilin on 2025/11/10.
//

import Cocoa
import SwiftUI

@MainActor
class LoadingIndicatorWindow {
    private var window: NSWindow?
    private var updateTimer: Timer?
    
    func show() {
        guard window == nil else { return }
        
        // Get mouse cursor position
        let mouseLocation = NSEvent.mouseLocation
        
        // Create the loading view
        let loadingView = LoadingIndicatorView()
        let hostingView = NSHostingView(rootView: loadingView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 160, height: 40)
        
        // Create a borderless, floating window
        let panel = NSPanel(
            contentRect: NSRect(x: mouseLocation.x + 20, y: mouseLocation.y - 20, width: 160, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.hidesOnDeactivate = false
        
        panel.orderFrontRegardless()
        
        self.window = panel
        
        // Start tracking cursor movement
        startTrackingCursor()
    }
    
    func hide() {
        stopTrackingCursor()
        window?.close()
        window = nil
    }
    
    private func startTrackingCursor() {
        // Update position every 16ms (~60fps) to follow cursor smoothly
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePosition()
            }
        }
    }
    
    private func stopTrackingCursor() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updatePosition() {
        guard let window = window else { return }
        
        // Get current mouse position
        let mouseLocation = NSEvent.mouseLocation
        
        // Calculate new window position (offset from cursor)
        let newOrigin = NSPoint(
            x: mouseLocation.x + 20,
            y: mouseLocation.y - 20
        )
        
        // Smoothly move window to new position
        window.setFrameOrigin(newOrigin)
    }
}

struct LoadingIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Spinner
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
                .scaleEffect(0.8)
            
            // Text
            Text("Rewriting...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .frame(height: 40)
    }
}

#Preview {
    LoadingIndicatorView()
        .frame(width: 100, height: 100)
}

