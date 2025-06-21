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
        let windowSize = recording ? NSSize(width: 140, height: 36) : NSSize(width: 44, height: 44)
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
            x: screenFrame.maxX - windowFrame.width - 10,  // Changed from 20 to 10 to match statusWindow
            y: screenFrame.maxY - windowFrame.height - 10  // Changed from 20 to 10 to match statusWindow
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
    @State private var shimmerOffset: CGFloat = -100
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                ZStack {
                    // Red gradient background
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.8, green: 0, blue: 0.2), Color(red: 1.0, green: 0.2, blue: 0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    // Shimmer effect overlay
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.3), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .mask(
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 20, height: 28)
                                .offset(x: shimmerOffset)
                        )
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text("Hearing you...")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.8, green: 0, blue: 0.2), Color(red: 1.0, green: 0.2, blue: 0.3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
            }
            .padding(4)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 100
            }
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
        statusWindow?.setContentSize(NSSize(width: 140, height: 36))
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
    @State private var opacity: Double = 0.7
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(opacity))
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            opacity = 1.0
                        }
                    }
            }
            
            Text("⌘x3 to Record")
                .font(.system(size: 12))
                .foregroundColor(.black.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.7))
                .cornerRadius(4)
        }
        .padding(4)
    }
}