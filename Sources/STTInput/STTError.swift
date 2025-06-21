import Foundation

/// Comprehensive error handling for STT Input application
enum STTError: LocalizedError, Equatable {
    // MARK: - Permission Errors
    case microphonePermissionDenied
    case accessibilityPermissionDenied
    
    // MARK: - Audio Errors
    case audioSetupFailed(underlying: String)
    case audioRecordingFailed(underlying: String)
    case audioDataEmpty
    
    // MARK: - Transcription Errors
    case transcriptionFailed(underlying: String)
    case apiKeyMissing
    case networkUnavailable
    case apiQuotaExceeded
    case audioTooLong
    case audioTooShort
    
    // MARK: - Text Injection Errors
    case textInjectionFailed(underlying: String)
    
    // MARK: - System Errors
    case unexpectedError(underlying: String)
    
    // MARK: - LocalizedError Implementation
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access denied"
        case .accessibilityPermissionDenied:
            return "Accessibility access denied"
        case .audioSetupFailed(let message):
            return "Audio setup failed: \(message)"
        case .audioRecordingFailed(let message):
            return "Recording failed: \(message)"
        case .audioDataEmpty:
            return "No audio recorded"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .apiKeyMissing:
            return "OpenAI API key not configured"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .apiQuotaExceeded:
            return "API quota exceeded"
        case .audioTooLong:
            return "Audio recording too long"
        case .audioTooShort:
            return "Audio recording too short"
        case .textInjectionFailed(let message):
            return "Text insertion failed: \(message)"
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Grant microphone access in System Preferences > Security & Privacy > Microphone"
        case .accessibilityPermissionDenied:
            return "Grant accessibility access in System Preferences > Security & Privacy > Accessibility"
        case .audioSetupFailed, .audioRecordingFailed:
            return "Check your microphone connection and try again"
        case .audioDataEmpty, .audioTooShort:
            return "Try recording for a longer duration"
        case .transcriptionFailed:
            return "Check your network connection and try again"
        case .apiKeyMissing:
            return "Configure your OpenAI API key in the application settings"
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .apiQuotaExceeded:
            return "Wait for your API quota to reset or upgrade your OpenAI plan"
        case .audioTooLong:
            return "Try recording shorter audio clips"
        case .textInjectionFailed:
            return "Ensure the target application accepts text input"
        case .unexpectedError:
            return "Please restart the application and try again"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .microphonePermissionDenied:
            return "The application doesn't have permission to access the microphone"
        case .accessibilityPermissionDenied:
            return "The application doesn't have permission to monitor input events"
        case .audioSetupFailed:
            return "Failed to initialize audio recording system"
        case .audioRecordingFailed:
            return "The audio recording process encountered an error"
        case .audioDataEmpty:
            return "No audio data was captured during recording"
        case .transcriptionFailed:
            return "The speech-to-text service failed to process the audio"
        case .apiKeyMissing:
            return "No OpenAI API key found in secure storage"
        case .networkUnavailable:
            return "Cannot connect to the transcription service"
        case .apiQuotaExceeded:
            return "OpenAI API usage limits have been exceeded"
        case .audioTooLong:
            return "Audio exceeds maximum duration limit"
        case .audioTooShort:
            return "Audio is too short to transcribe accurately"
        case .textInjectionFailed:
            return "Failed to insert transcribed text into the active application"
        case .unexpectedError:
            return "An unexpected system error occurred"
        }
    }
    
    // MARK: - Error Classification
    
    var isRecoverable: Bool {
        switch self {
        case .microphonePermissionDenied, .accessibilityPermissionDenied, .apiKeyMissing:
            return false // Requires user action outside the app
        case .networkUnavailable, .audioSetupFailed, .audioRecordingFailed, .transcriptionFailed:
            return true // Can retry
        case .audioDataEmpty, .audioTooShort, .audioTooLong:
            return true // User can record again
        case .apiQuotaExceeded:
            return false // Requires waiting or upgrading
        case .textInjectionFailed:
            return true // Can retry
        case .unexpectedError:
            return true // Can retry
        }
    }
    
    var shouldShowUserNotification: Bool {
        switch self {
        case .microphonePermissionDenied, .accessibilityPermissionDenied, .apiKeyMissing:
            return true // Critical setup issues
        case .networkUnavailable, .apiQuotaExceeded:
            return true // Service issues
        case .audioDataEmpty, .audioTooShort, .audioTooLong:
            return false // Minor user issues, can show in UI
        case .audioSetupFailed, .audioRecordingFailed, .transcriptionFailed, .textInjectionFailed:
            return false // Show in overlay instead
        case .unexpectedError:
            return true // Serious issues
        }
    }
}

// MARK: - Error Creation Helpers

extension STTError {
    static func from(_ error: Error) -> STTError {
        if let sttError = error as? STTError {
            return sttError
        }
        
        let errorMessage = error.localizedDescription
        
        // Try to classify common system errors
        let lowercaseMessage = errorMessage.lowercased()
        if lowercaseMessage.contains("network") || lowercaseMessage.contains("connection") {
            return .networkUnavailable
        } else if lowercaseMessage.contains("permission") && lowercaseMessage.contains("denied") {
            return .accessibilityPermissionDenied
        } else if lowercaseMessage.contains("audio") || lowercaseMessage.contains("recording") {
            return .audioRecordingFailed(underlying: errorMessage)
        } else {
            return .unexpectedError(underlying: errorMessage)
        }
    }
}