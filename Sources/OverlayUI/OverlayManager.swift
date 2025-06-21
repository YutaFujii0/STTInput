import SwiftUI
import AppKit

public class OverlayManager: ObservableObject {
    private var micWindow: NSWindow?
    private var statusWindow: NSWindow?
    private var hideTimer: Timer?
    private var statusHideTimer: Timer?
    private let displayDuration: TimeInterval = 5.0
    private let statusDisplayDuration: TimeInterval = 5.0
    private var isRecording = false
    
    public var onMicButtonTapped: (() -> Void)?
    public var onStopButtonTapped: (() -> Void)?
    
    public init() {}
    
    public func showStatusIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.createStatusWindow()
            self?.startStatusHideTimer()
        }
    }
    
    public func hideStatusIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.statusHideTimer?.invalidate()
            self?.statusWindow?.close()
            self?.statusWindow = nil
        }
    }
    
    private func startStatusHideTimer() {
        statusHideTimer?.invalidate()
        statusHideTimer = Timer.scheduledTimer(withTimeInterval: statusDisplayDuration, repeats: false) { [weak self] _ in
            self?.hideStatusIndicator()
        }
    }
    
    public func showMicButton() {
        DispatchQueue.main.async { [weak self] in
            self?.createMicWindow(recording: false)
            self?.positionWindowNearCursor()
            self?.startHideTimer()
        }
    }
    
    public func showStopButton() {
        print("OverlayManager: showStopButton called")
        DispatchQueue.main.async { [weak self] in
            print("OverlayManager: Creating stop button window")
            self?.isRecording = true
            self?.hideTimer?.invalidate()
            self?.hideStatusIndicator() // Hide status indicator when recording
            self?.createMicWindow(recording: true)
            self?.positionWindowNearCursor()
        }
    }
    
    public func hideMicButton() {
        DispatchQueue.main.async { [weak self] in
            self?.micWindow?.close()
            self?.micWindow = nil
            self?.hideTimer?.invalidate()
            self?.isRecording = false
        }
    }
    
    private func createMicWindow(recording: Bool) {
        print("Creating window, recording: \(recording)")
        micWindow?.close()
        micWindow = nil
        
        let contentView: AnyView
        if recording {
            contentView = AnyView(StopButtonView { [weak self] in
                self?.onStopButtonTapped?()
                self?.hideMicButton()
            })
        } else {
            contentView = AnyView(MicButtonView { [weak self] in
                self?.onMicButtonTapped?()
                self?.showStopButton()
            })
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        
        micWindow = NSWindow(contentViewController: hostingController)
        micWindow?.styleMask = [.borderless]
        micWindow?.level = .statusBar
        micWindow?.backgroundColor = .clear
        micWindow?.isOpaque = false
        micWindow?.hasShadow = true
        let windowSize = recording ? NSSize(width: 120, height: 60) : NSSize(width: 44, height: 44)
        micWindow?.setContentSize(windowSize)
        micWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        micWindow?.isReleasedWhenClosed = false
        
        micWindow?.orderFront(nil)
        micWindow?.makeKeyAndOrderFront(nil)
        print("Window created and ordered to front")
    }
    
    private func positionWindowNearCursor() {
        guard let window = micWindow else { 
            print("No window to position")
            return 
        }
        
        // Position in the top-right corner of the screen for better visibility
        guard let screen = NSScreen.main else { 
            print("No main screen found")
            return 
        }
        let screenFrame = screen.visibleFrame
        
        var windowFrame = window.frame
        windowFrame.origin = CGPoint(
            x: screenFrame.maxX - windowFrame.width - 20,
            y: screenFrame.maxY - windowFrame.height - 20
        )
        
        print("Positioning window at: \(windowFrame)")
        window.setFrame(windowFrame, display: true)
    }
    
    private func startHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { [weak self] _ in
            self?.hideMicButton()
        }
    }
}

struct MicButtonView: View {
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "mic.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(isHovered ? Color.blue : Color.blue.opacity(0.8))
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct StopButtonView: View {
    let onTap: () -> Void
    @State private var isHovered = false
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: onTap) {
                ZStack {
                    // Pulsing background
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0.0 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: isPulsing)
                    
                    // Main button
                    Circle()
                        .fill(isHovered ? Color.red : Color.red.opacity(0.8))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .shadow(radius: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovered = hovering
            }
            
            Text("⌘⌘ to stop")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

extension OverlayManager {
    private func createStatusWindow() {
        statusWindow?.close()
        statusWindow = nil
        
        let contentView = StatusIndicatorView()
        let hostingController = NSHostingController(rootView: contentView)
        
        statusWindow = NSWindow(contentViewController: hostingController)
        statusWindow?.styleMask = [.borderless]
        statusWindow?.level = .statusBar
        statusWindow?.backgroundColor = .clear
        statusWindow?.isOpaque = false
        statusWindow?.hasShadow = false
        statusWindow?.setContentSize(NSSize(width: 30, height: 30))
        statusWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        statusWindow?.isReleasedWhenClosed = false
        
        // Position in top-right corner
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            var windowFrame = statusWindow!.frame
            windowFrame.origin = CGPoint(
                x: screenFrame.maxX - windowFrame.width - 10,
                y: screenFrame.maxY - windowFrame.height - 10
            )
            statusWindow?.setFrame(windowFrame, display: true)
        }
        
        statusWindow?.orderFront(nil)
    }
}

struct StatusIndicatorView: View {
    @State private var opacity: Double = 0.6
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 28, height: 28)
            
            Image(systemName: "mic.fill")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(opacity))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        opacity = 1.0
                    }
                }
        }
        .frame(width: 30, height: 30)
    }
}