import Foundation
import AppKit
import AudioCaptureKit
import WhisperClient
import TextInjector
import OverlayUI
import InputMonitorKit

/// Coordinates the entire recording-to-text workflow
@MainActor
final class RecordingCoordinator {
    
    // MARK: - Dependencies
    
    private let appState: AppState
    private let audioRecorder: AudioRecorder
    private let whisperClient: WhisperClient
    private let textInjector: TextInjector
    private let overlayManager: OverlayManager
    private let inputMonitor: InputMonitor
    
    // MARK: - Configuration
    
    private let minDisplayTime: TimeInterval = 0.8
    private let preProcessingDelay: TimeInterval = 0.1
    
    // MARK: - Initialization
    
    init(
        appState: AppState,
        audioRecorder: AudioRecorder,
        whisperClient: WhisperClient,
        textInjector: TextInjector,
        overlayManager: OverlayManager,
        inputMonitor: InputMonitor
    ) {
        self.appState = appState
        self.audioRecorder = audioRecorder
        self.whisperClient = whisperClient
        self.textInjector = textInjector
        self.overlayManager = overlayManager
        self.inputMonitor = inputMonitor
    }
    
    // MARK: - Public Interface
    
    /// Starts the recording process
    func startRecording() async {
        guard appState.canStartRecording else {
            let error: STTError = appState.microphonePermission != .granted 
                ? .microphonePermissionDenied 
                : .accessibilityPermissionDenied
            appState.setError(error)
            return
        }
        
        print("Starting recording...")
        appState.setRecordingState(.recording)
        inputMonitor.setRecordingState(true) // Sync InputMonitor state
        
        // Provide audio feedback
        NSSound.beep()
        
        // Show recording UI
        overlayManager.showStopButton()
        
        // Start audio capture
        audioRecorder.startRecording { [weak self] audioData in
            guard let self = self else { return }
            
            Task { @MainActor in
                await self.handleRecordingComplete(audioData: audioData)
            }
        }
    }
    
    /// Stops the recording process
    func stopRecording() async {
        guard appState.isRecording else { return }
        
        print("Stopping recording...")
        audioRecorder.stopRecording()
        
        // Update state will be handled in completion callback
        appState.setRecordingState(.idle)
        inputMonitor.setRecordingState(false) // Sync InputMonitor state
        overlayManager.hideMicButton()
    }
    
    // MARK: - Private Implementation
    
    private func handleRecordingComplete(audioData: Data) async {
        // Validate audio data
        guard !audioData.isEmpty else {
            appState.setError(.audioDataEmpty)
            overlayManager.hideMicButton()
            return
        }
        
        print("Recording completed, got audio data: \(audioData.count) bytes")
        
        // Update state to processing
        appState.setRecordingState(.processing)
        inputMonitor.setRecordingState(false) // Recording is done, sync state
        overlayManager.hideMicButton()
        
        // Process the transcription
        await processTranscription(audioData: audioData)
    }
    
    private func processTranscription(audioData: Data) async {
        do {
            // Small delay to ensure recording UI has time to update
            try await Task.sleep(nanoseconds: UInt64(preProcessingDelay * 1_000_000_000))
            
            // Show processing indicator
            overlayManager.showProcessingIndicator()
            
            let startTime = Date()
            
            // Perform transcription
            let text = try await whisperClient.transcribe(audioData: audioData)
            
            // Ensure minimum display time for processing indicator
            let elapsed = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, minDisplayTime - elapsed)
            
            if remainingTime > 0 {
                try await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }
            
            // Handle successful transcription
            await handleTranscriptionSuccess(text: text)
            
        } catch {
            await handleTranscriptionError(error)
        }
    }
    
    private func handleTranscriptionSuccess(text: String?) async {
        let transcribedText = text ?? ""
        
        // Update state
        appState.setLastTranscribedText(transcribedText)
        appState.setRecordingState(.idle)
        
        // Hide processing UI
        overlayManager.hideProcessingIndicator()
        
        // Insert text if not empty
        if !transcribedText.isEmpty {
            textInjector.insertText(transcribedText)
        }
        
        print("Transcription completed successfully")
    }
    
    private func handleTranscriptionError(_ error: Error) async {
        print("Transcription error: \(error)")
        
        // Convert to STTError
        let sttError = STTError.from(error)
        
        // Update state
        appState.setError(sttError)
        
        // Hide processing UI
        overlayManager.hideProcessingIndicator()
    }
}

// MARK: - Error Handling Extensions

extension RecordingCoordinator {
    
    /// Retries the last operation if it's recoverable
    func retryLastOperation() async {
        guard let lastError = appState.lastError, lastError.isRecoverable else {
            return
        }
        
        appState.clearError()
        
        // Only retry recording start for now
        // More sophisticated retry logic can be added based on error type
        if case .audioSetupFailed = lastError {
            await startRecording()
        }
    }
    
    /// Handles permission-related errors by showing appropriate guidance
    func handlePermissionError(_ error: STTError) {
        appState.setError(error)
        
        // Could trigger a permission request UI here in the future
        print("Permission error: \(error.localizedDescription)")
        print("Recovery: \(error.recoverySuggestion ?? "Unknown")")
    }
}