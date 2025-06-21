import SwiftUI
import Foundation

/// Centralized application state management
@MainActor
final class AppState: ObservableObject {
    // MARK: - State Enums
    
    enum RecordingState: Equatable {
        case idle
        case recording
        case processing
        case error(STTError)
    }
    
    enum PermissionStatus {
        case unknown
        case granted
        case denied
        case requesting
    }
    
    // MARK: - Published State
    
    @Published var recordingState: RecordingState = .idle
    @Published var microphonePermission: PermissionStatus = .unknown
    @Published var accessibilityPermission: PermissionStatus = .unknown
    @Published var lastTranscribedText: String = ""
    @Published var lastError: STTError?
    
    // MARK: - Computed Properties
    
    var isRecording: Bool {
        if case .recording = recordingState { return true }
        return false
    }
    
    var isProcessing: Bool {
        if case .processing = recordingState { return true }
        return false
    }
    
    var canStartRecording: Bool {
        guard case .idle = recordingState else { return false }
        return microphonePermission == .granted && accessibilityPermission == .granted
    }
    
    var hasError: Bool {
        if case .error = recordingState { return true }
        return lastError != nil
    }
    
    // MARK: - State Updates
    
    func setRecordingState(_ state: RecordingState) {
        recordingState = state
        
        // Clear error when starting new recording
        if case .recording = state {
            lastError = nil
        }
    }
    
    func setMicrophonePermission(_ status: PermissionStatus) {
        microphonePermission = status
    }
    
    func setAccessibilityPermission(_ status: PermissionStatus) {
        accessibilityPermission = status
    }
    
    func setLastTranscribedText(_ text: String) {
        lastTranscribedText = text
    }
    
    func setError(_ error: STTError) {
        lastError = error
        recordingState = .error(error)
    }
    
    func clearError() {
        lastError = nil
        if case .error = recordingState {
            recordingState = .idle
        }
    }
}