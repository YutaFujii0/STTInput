import SwiftUI
import InputMonitorKit
import OverlayUI
import AudioCaptureKit
import WhisperClient
import TextInjector

@main
struct STTInputApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var inputMonitor: InputMonitor?
    private var overlayManager: OverlayManager?
    private var audioRecorder: AudioRecorder?
    private var whisperClient: WhisperClient?
    private var textInjector: TextInjector?
    private var isRecording = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApp()
        requestPermissions()
        
        // Delay service start to ensure permissions are granted
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.startServices()
        }
    }
    
    private func setupApp() {
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func requestPermissions() {
        PermissionManager.shared.requestMicrophoneAccess()
        PermissionManager.shared.requestAccessibilityAccess()
    }
    
    private func startServices() {
        inputMonitor = InputMonitor()
        overlayManager = OverlayManager()
        audioRecorder = AudioRecorder()
        whisperClient = WhisperClient()
        textInjector = TextInjector()
        
        // Show mic indicator when user focuses on input field
        inputMonitor?.onInputFieldFocus = { [weak self] in
            guard !(self?.isRecording ?? false) else { return }
            self?.overlayManager?.showStatusIndicator()
        }
        
        // Triple Cmd press to start recording
        inputMonitor?.onTripleCmdPress = { [weak self] in
            guard !(self?.isRecording ?? false) else { return }
            self?.startRecording()
        }
        
        // Double Cmd press to stop recording
        inputMonitor?.onDoubleCmdPress = { [weak self] in
            guard self?.isRecording ?? false else { return }
            self?.stopRecording()
        }
        
        overlayManager?.onStopButtonTapped = { [weak self] in
            self?.stopRecording()
        }
        
        inputMonitor?.start()
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        print("Starting recording...")
        isRecording = true
        inputMonitor?.setRecordingState(true)
        
        // Play system sound for feedback
        NSSound.beep()
        
        print("Showing stop button...")
        overlayManager?.showStopButton()
        
        audioRecorder?.startRecording { [weak self] audioData in
            print("Recording completed, got audio data: \(audioData.count) bytes")
            self?.isRecording = false
            self?.inputMonitor?.setRecordingState(false)
            self?.overlayManager?.hideMicButton()
            self?.transcribeAudio(audioData)
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stopRecording()
        isRecording = false
        inputMonitor?.setRecordingState(false)
        overlayManager?.hideMicButton()
    }
    
    private func transcribeAudio(_ audioData: Data) {
        Task {
            // Small delay to ensure recording UI has time to hide
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            await MainActor.run {
                // Show processing indicator
                self.overlayManager?.showProcessingIndicator()
            }
            
            let startTime = Date()
            
            do {
                let text = try await whisperClient?.transcribe(audioData: audioData)
                
                // Ensure minimum 0.8 second display time
                let elapsed = Date().timeIntervalSince(startTime)
                let minDisplayTime: TimeInterval = 0.8
                let remainingTime = max(0, minDisplayTime - elapsed)
                
                if remainingTime > 0 {
                    try await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
                }
                
                await MainActor.run {
                    // Hide processing indicator and insert text
                    self.overlayManager?.hideProcessingIndicator()
                    self.textInjector?.insertText(text ?? "")
                }
            } catch {
                print("Transcription error: \(error)")
                await MainActor.run {
                    // Hide processing indicator even on error
                    self.overlayManager?.hideProcessingIndicator()
                }
            }
        }
    }
}