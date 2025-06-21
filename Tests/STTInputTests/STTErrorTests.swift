import XCTest
@testable import STTInput

final class STTErrorTests: XCTestCase {
    
    func testErrorEquality() {
        let error1 = STTError.audioDataEmpty
        let error2 = STTError.audioDataEmpty
        let error3 = STTError.microphonePermissionDenied
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        
        let error4 = STTError.audioSetupFailed(underlying: "test")
        let error5 = STTError.audioSetupFailed(underlying: "test")
        let error6 = STTError.audioSetupFailed(underlying: "different")
        
        XCTAssertEqual(error4, error5)
        XCTAssertNotEqual(error4, error6)
    }
    
    func testErrorDescriptions() {
        XCTAssertEqual(STTError.microphonePermissionDenied.errorDescription, "Microphone access denied")
        XCTAssertEqual(STTError.audioDataEmpty.errorDescription, "No audio recorded")
        XCTAssertEqual(STTError.apiKeyMissing.errorDescription, "OpenAI API key not configured")
        
        let customError = STTError.transcriptionFailed(underlying: "Network error")
        XCTAssertEqual(customError.errorDescription, "Transcription failed: Network error")
    }
    
    func testRecoverySuggestions() {
        XCTAssertTrue(STTError.microphonePermissionDenied.recoverySuggestion?.contains("System Preferences") == true)
        XCTAssertTrue(STTError.apiKeyMissing.recoverySuggestion?.contains("API key") == true)
        XCTAssertTrue(STTError.networkUnavailable.recoverySuggestion?.contains("internet connection") == true)
    }
    
    func testRecoverableClassification() {
        // Non-recoverable errors (require user action outside app)
        XCTAssertFalse(STTError.microphonePermissionDenied.isRecoverable)
        XCTAssertFalse(STTError.accessibilityPermissionDenied.isRecoverable)
        XCTAssertFalse(STTError.apiKeyMissing.isRecoverable)
        XCTAssertFalse(STTError.apiQuotaExceeded.isRecoverable)
        
        // Recoverable errors (can retry)
        XCTAssertTrue(STTError.networkUnavailable.isRecoverable)
        XCTAssertTrue(STTError.audioSetupFailed(underlying: "").isRecoverable)
        XCTAssertTrue(STTError.audioRecordingFailed(underlying: "").isRecoverable)
        XCTAssertTrue(STTError.transcriptionFailed(underlying: "").isRecoverable)
        XCTAssertTrue(STTError.audioDataEmpty.isRecoverable)
        XCTAssertTrue(STTError.audioTooShort.isRecoverable)
        XCTAssertTrue(STTError.audioTooLong.isRecoverable)
        XCTAssertTrue(STTError.textInjectionFailed(underlying: "").isRecoverable)
        XCTAssertTrue(STTError.unexpectedError(underlying: "").isRecoverable)
    }
    
    func testUserNotificationRequirement() {
        // Critical setup issues should show notifications
        XCTAssertTrue(STTError.microphonePermissionDenied.shouldShowUserNotification)
        XCTAssertTrue(STTError.accessibilityPermissionDenied.shouldShowUserNotification)
        XCTAssertTrue(STTError.apiKeyMissing.shouldShowUserNotification)
        XCTAssertTrue(STTError.networkUnavailable.shouldShowUserNotification)
        XCTAssertTrue(STTError.apiQuotaExceeded.shouldShowUserNotification)
        XCTAssertTrue(STTError.unexpectedError(underlying: "").shouldShowUserNotification)
        
        // Minor issues should not show notifications (show in overlay instead)
        XCTAssertFalse(STTError.audioDataEmpty.shouldShowUserNotification)
        XCTAssertFalse(STTError.audioTooShort.shouldShowUserNotification)
        XCTAssertFalse(STTError.audioTooLong.shouldShowUserNotification)
        XCTAssertFalse(STTError.audioSetupFailed(underlying: "").shouldShowUserNotification)
        XCTAssertFalse(STTError.audioRecordingFailed(underlying: "").shouldShowUserNotification)
        XCTAssertFalse(STTError.transcriptionFailed(underlying: "").shouldShowUserNotification)
        XCTAssertFalse(STTError.textInjectionFailed(underlying: "").shouldShowUserNotification)
    }
    
    func testErrorCreationFromGenericError() {
        // Test network error classification
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "No network connection"])
        let sttNetworkError = STTError.from(networkError)
        XCTAssertEqual(sttNetworkError, .networkUnavailable)
        
        // Test audio error classification
        let audioError = NSError(domain: "AudioError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio recording failed"])
        let sttAudioError = STTError.from(audioError)
        if case .audioRecordingFailed(let message) = sttAudioError {
            XCTAssertTrue(message.contains("Audio recording failed"))
        } else {
            XCTFail("Should be audio recording failed error")
        }
        
        // Test permission error classification
        let permissionError = NSError(domain: "PermissionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
        let sttPermissionError = STTError.from(permissionError)
        XCTAssertEqual(sttPermissionError, .accessibilityPermissionDenied)
        
        // Test unknown error fallback
        let unknownError = NSError(domain: "UnknownError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        let sttUnknownError = STTError.from(unknownError)
        if case .unexpectedError(let message) = sttUnknownError {
            XCTAssertTrue(message.contains("Something went wrong"))
        } else {
            XCTFail("Should be unexpected error")
        }
        
        // Test STTError passthrough
        let originalSTTError = STTError.apiKeyMissing
        let passthroughError = STTError.from(originalSTTError)
        XCTAssertEqual(passthroughError, originalSTTError)
    }
    
    func testFailureReasons() {
        XCTAssertTrue(STTError.microphonePermissionDenied.failureReason?.contains("permission") == true)
        XCTAssertTrue(STTError.audioSetupFailed(underlying: "").failureReason?.contains("initialize") == true)
        XCTAssertTrue(STTError.networkUnavailable.failureReason?.contains("connect") == true)
    }
}