import SwiftUI
import AppKit

public class OverlayManager: ObservableObject {
    private var micWindow: NSWindow?
    private var hideTimer: Timer?
    private let displayDuration: TimeInterval = 5.0
    private var isRecording = false
    
    public var onMicButtonTapped: (() -> Void)?
    public var onStopButtonTapped: (() -> Void)?
    
    public init() {}
    
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
        micWindow?.level = .floating
        micWindow?.backgroundColor = .clear
        micWindow?.isOpaque = false
        micWindow?.hasShadow = true
        micWindow?.setContentSize(NSSize(width: 44, height: 44))
        micWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        micWindow?.isReleasedWhenClosed = false
        
        micWindow?.orderFront(nil)
    }
    
    private func positionWindowNearCursor() {
        guard let window = micWindow else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        var windowFrame = window.frame
        windowFrame.origin = CGPoint(x: mouseLocation.x + 10, y: mouseLocation.y - windowFrame.height - 10)
        
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
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "stop.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(isHovered ? Color.red : Color.red.opacity(0.8))
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}