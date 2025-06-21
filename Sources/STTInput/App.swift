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
            do {
                let text = try await whisperClient?.transcribe(audioData: audioData)
                await MainActor.run {
                    self.textInjector?.insertText(text ?? "")
                }
            } catch {
                print("Transcription error: \(error)")
            }
        }
    }
}