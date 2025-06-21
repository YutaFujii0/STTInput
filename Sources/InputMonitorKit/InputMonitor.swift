import Cocoa

public class InputMonitor {
    private var eventMonitor: Any?
    private var flagsMonitor: Any?
    private var mouseMonitor: Any?
    
    // Cmd detection
    private var cmdPressCount = 0
    private var lastCmdPressTime: Date?
    private let cmdPressInterval: TimeInterval = 0.5
    private var cmdResetTimer: Timer?
    private var isRecording = false
    
    public var onTripleCmdPress: (() -> Void)?
    public var onDoubleCmdPress: (() -> Void)?
    public var onInputFieldFocus: (() -> Void)?
    
    public init() {}
    
    public func start() {
        guard AXIsProcessTrusted() else {
            print("PERMISSION ERROR: Accessibility permission required for STTInput")
            print("To fix: System Preferences → Security & Privacy → Privacy → Accessibility")
            print("Add: /Users/yuta/code/hobby/stt-input-macos/STTInput/.build/release/STTInput")
            requestAccessibilityPermission()            
            return
        }
        
        // Monitor for modifier key changes (to detect Cmd press/release)
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        // Monitor for mouse clicks (to detect input field focus)
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleMouseClick(event)
        }
        
        // Monitor for keyboard input (to detect typing)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
        }
    }
    
    public func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
        cmdResetTimer?.invalidate()
    }
    
    private func handleMouseClick(_ event: NSEvent) {
        // When user clicks, notify that they might be focusing on an input field
        onInputFieldFocus?()
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        // Skip modifier keys
        if isModifierKey(event) { return }
        
        // When user types (not just modifiers), they're likely in an input field
        onInputFieldFocus?()
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        // Check if Command key was pressed (not just held)
        if event.keyCode == 55 { // Command key
            let cmdPressed = event.modifierFlags.contains(.command)
            
            // We only care about key down events (when cmd is pressed, not released)
            if cmdPressed && !event.modifierFlags.contains(.shift) && 
               !event.modifierFlags.contains(.option) && 
               !event.modifierFlags.contains(.control) {
                handleCmdPress()
            }
        }
    }
    
    private func handleCmdPress() {
        let now = Date()
        
        // Reset count if too much time has passed
        if let lastPress = lastCmdPressTime, now.timeIntervalSince(lastPress) > cmdPressInterval {
            cmdPressCount = 0
        }
        
        cmdPressCount += 1
        lastCmdPressTime = now
        
        // Reset timer
        cmdResetTimer?.invalidate()
        cmdResetTimer = Timer.scheduledTimer(withTimeInterval: cmdPressInterval, repeats: false) { [weak self] _ in
            self?.cmdPressCount = 0
        }
        
        // Check for double press when recording
        if cmdPressCount == 2 && isRecording {
            cmdPressCount = 0
            cmdResetTimer?.invalidate()
            onDoubleCmdPress?()
            return
        }
        
        // Check for triple press when not recording
        if cmdPressCount >= 3 && !isRecording {
            cmdPressCount = 0
            cmdResetTimer?.invalidate()
            onTripleCmdPress?()
        }
    }
    
    public func setRecordingState(_ recording: Bool) {
        isRecording = recording
        cmdPressCount = 0
        cmdResetTimer?.invalidate()
    }
    
    private func isModifierKey(_ event: NSEvent) -> Bool {
        return event.keyCode == 55 || // Command
               event.keyCode == 56 || // Shift
               event.keyCode == 58 || // Option
               event.keyCode == 59 || // Control
               event.keyCode == 57 || // Caps Lock
               event.keyCode == 63    // Function
    }
    
    private func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    deinit {
        stop()
    }
}