import Cocoa

public class InputMonitor {
    private var eventMonitor: Any?
    private var lastKeyPressTime: Date?
    private let debounceInterval: TimeInterval = 1.0
    private var debounceTimer: Timer?
    
    public var onKeyboardInput: (() -> Void)?
    
    public init() {}
    
    public func start() {
        guard AXIsProcessTrusted() else {
            print("Accessibility permission required")
            requestAccessibilityPermission()
            return
        }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
    }
    
    public func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        debounceTimer?.invalidate()
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard !isModifierKey(event) else { return }
        
        lastKeyPressTime = Date()
        
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.onKeyboardInput?()
        }
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