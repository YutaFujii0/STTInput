import AppKit
import Carbon

public class TextInjector {
    public init() {}
    
    public func insertText(_ text: String) {
        // Try clipboard method first (more reliable)
        if insertViaClipboard(text) {
            return
        }
        
        // Fallback to virtual keypresses
        insertViaKeypresses(text)
    }
    
    private func insertViaClipboard(_ text: String) -> Bool {
        // Save current clipboard content
        let pasteboard = NSPasteboard.general
        let oldContent = pasteboard.string(forType: .string)
        
        // Set new content
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Simulate Cmd+V
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down Cmd
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand
        
        // Key down V
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        
        // Key up V
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        
        // Key up Cmd
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        // Post events
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        // Restore clipboard after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let oldContent = oldContent {
                pasteboard.clearContents()
                pasteboard.setString(oldContent, forType: .string)
            }
        }
        
        return true
    }
    
    private func insertViaKeypresses(_ text: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        for character in text {
            if let event = createKeyEvent(for: character, source: source) {
                event.post(tap: .cghidEventTap)
                Thread.sleep(forTimeInterval: 0.01) // Small delay between keypresses
            }
        }
    }
    
    private func createKeyEvent(for character: Character, source: CGEventSource?) -> CGEvent? {
        let string = String(character)
        
        // Create a key down event
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        
        // Convert string to UTF-16
        let utf16 = Array(string.utf16)
        utf16.withUnsafeBufferPointer { buffer in
            keyDown?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: buffer.baseAddress)
        }
        
        return keyDown
    }
}