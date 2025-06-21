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

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    // MARK: - State Management
    
    private let appState = AppState()
    private let configuration = AppConfiguration.load()
    
    // MARK: - Services
    
    private var inputMonitor: InputMonitor?
    private var overlayManager: OverlayManager?
    private var audioRecorder: AudioRecorder?
    private var whisperClient: WhisperClient?
    private var textInjector: TextInjector?
    
    // MARK: - Coordinators
    
    private var recordingCoordinator: RecordingCoordinator?
    
    // MARK: - App Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApp()
        Task {
            await requestPermissions()
            await startServicesWithDelay()
        }
    }
    
    // MARK: - Setup
    
    private func setupApp() {
        // Set activation policy early and ensure app is ready
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: false)
        
        // Log startup information
        Logger.info("STTInput starting up...")
        Logger.info("Bundle path: \(Bundle.main.bundlePath)")
        Logger.info("Process ID: \(ProcessInfo.processInfo.processIdentifier)")
        
        // Validate configuration
        if !configuration.isValid {
            print("Configuration validation failed:")
            configuration.validationErrors.forEach { print("- \($0)") }
        }
    }
    
    private func requestPermissions() async {
        appState.setMicrophonePermission(.requesting)
        appState.setAccessibilityPermission(.requesting)
        
        // Request permissions
        PermissionManager.shared.requestMicrophoneAccess()
        PermissionManager.shared.requestAccessibilityAccess()
        
        // Note: In a real implementation, you'd want to check the actual permission status
        // For now, we'll assume they're granted after a delay
        try? await Task.sleep(nanoseconds: UInt64(1.0 * 1_000_000_000))
        
        appState.setMicrophonePermission(.granted)
        appState.setAccessibilityPermission(.granted)
    }
    
    private func startServicesWithDelay() async {
        // Delay service start to ensure permissions are granted
        try? await Task.sleep(nanoseconds: UInt64(configuration.serviceStartDelay * 1_000_000_000))
        
        await startServices()
    }
    
    private func startServices() async {
        Logger.info("Initializing services...")
        
        // Initialize services
        inputMonitor = InputMonitor()
        overlayManager = OverlayManager()
        audioRecorder = AudioRecorder()
        whisperClient = WhisperClient()
        textInjector = TextInjector()
        
        // Ensure all services are available
        guard let inputMonitor = inputMonitor,
              let overlayManager = overlayManager,
              let audioRecorder = audioRecorder,
              let whisperClient = whisperClient,
              let textInjector = textInjector else {
            print("ERROR: Failed to initialize one or more services")
            appState.setError(.unexpectedError(underlying: "Failed to initialize services"))
            return
        }
        
        Logger.info("All services initialized successfully")
        
        // Create recording coordinator
        recordingCoordinator = RecordingCoordinator(
            appState: appState,
            audioRecorder: audioRecorder,
            whisperClient: whisperClient,
            textInjector: textInjector,
            overlayManager: overlayManager,
            inputMonitor: inputMonitor
        )
        
        setupInputHandlers(inputMonitor: inputMonitor, overlayManager: overlayManager)
        
        // Start input monitoring
        inputMonitor.start()
        
        Logger.info("Services started successfully - STTInput is ready!")
        Logger.info("To use: Click in a text field or press Cmd 3 times to start recording")
    }
    
    private func setupInputHandlers(inputMonitor: InputMonitor, overlayManager: OverlayManager) {
        // Show mic indicator when user focuses on input field
        inputMonitor.onInputFieldFocus = { [weak self] in
            guard let self = self, !self.appState.isRecording else { return }
            overlayManager.showStatusIndicator()
        }
        
        // Triple Cmd press to start recording
        inputMonitor.onTripleCmdPress = { [weak self] in
            guard let self = self, !self.appState.isRecording else { return }
            Task { @MainActor in
                await self.recordingCoordinator?.startRecording()
            }
        }
        
        // Double Cmd press to stop recording
        inputMonitor.onDoubleCmdPress = { [weak self] in
            guard let self = self, self.appState.isRecording else { return }
            Task { @MainActor in
                await self.recordingCoordinator?.stopRecording()
            }
        }
        
        // Handle stop button tap from overlay
        overlayManager.onStopButtonTapped = { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                await self.recordingCoordinator?.stopRecording()
            }
        }
    }
}