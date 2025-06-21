import SwiftUI
import AppKit

public class OverlayManager: ObservableObject {
    private var micWindow: NSWindow?
    private var statusWindow: NSWindow?
    private var processingWindow: NSWindow?
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
        DispatchQueue.main.async { [weak self] in
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
    
    public func showProcessingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.hideTimer?.invalidate()
            self?.hideStatusIndicator()
            self?.createProcessingWindow()
        }
    }
    
    public func hideProcessingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.processingWindow?.close()
            self?.processingWindow = nil
        }
    }
    
    private func createProcessingWindow() {
        processingWindow?.close()
        processingWindow = nil
        
        let contentView = ProcessingView()
        let hostingController = NSHostingController(rootView: contentView)
        
        processingWindow = NSWindow(contentViewController: hostingController)
        processingWindow?.styleMask = [.borderless]
        processingWindow?.level = .statusBar
        processingWindow?.backgroundColor = .clear
        processingWindow?.isOpaque = false
        processingWindow?.hasShadow = false
        processingWindow?.setContentSize(NSSize(width: 140, height: 36))
        processingWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        processingWindow?.isReleasedWhenClosed = false
        
        // Position in top-right corner
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            var windowFrame = processingWindow!.frame
            windowFrame.origin = CGPoint(
                x: screenFrame.maxX - windowFrame.width - 10,
                y: screenFrame.maxY - windowFrame.height - 10
            )
            processingWindow?.setFrame(windowFrame, display: true)
        }
        
        processingWindow?.orderFront(nil)
    }
    
    private func createMicWindow(recording: Bool, processing: Bool = false) {
        micWindow?.close()
        micWindow = nil
        
        let contentView: AnyView
        if processing {
            contentView = AnyView(ProcessingView())
        } else if recording {
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
        let windowSize = (recording || processing) ? NSSize(width: 140, height: 36) : NSSize(width: 44, height: 44)
        micWindow?.setContentSize(windowSize)
        micWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        micWindow?.isReleasedWhenClosed = false
        
        micWindow?.orderFront(nil)
        micWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func positionWindowNearCursor() {
        guard let window = micWindow else { return }
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        var windowFrame = window.frame
        windowFrame.origin = CGPoint(
            x: screenFrame.maxX - windowFrame.width - 10,
            y: screenFrame.maxY - windowFrame.height - 10
        )
        
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

struct ProcessingView: View {
    @State private var isRotating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                // Blue gradient background
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.3, green: 0.5, blue: 1.0)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            isRotating = true
                        }
                    }
            }
            
            Text("Processing...")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.3, green: 0.5, blue: 1.0)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(4)
        }
        .padding(4)
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