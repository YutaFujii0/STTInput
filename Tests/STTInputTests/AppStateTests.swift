import XCTest
@testable import STTInput

@MainActor
final class AppStateTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        appState = AppState()
    }
    
    override func tearDown() {
        appState = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(appState.recordingState, .idle)
        XCTAssertEqual(appState.microphonePermission, .unknown)
        XCTAssertEqual(appState.accessibilityPermission, .unknown)
        XCTAssertEqual(appState.lastTranscribedText, "")
        XCTAssertNil(appState.lastError)
        XCTAssertFalse(appState.isRecording)
        XCTAssertFalse(appState.isProcessing)
        XCTAssertFalse(appState.canStartRecording)
        XCTAssertFalse(appState.hasError)
    }
    
    func testCanStartRecording() {
        // Initially cannot start recording
        XCTAssertFalse(appState.canStartRecording)
        
        // Grant microphone permission only
        appState.setMicrophonePermission(.granted)
        XCTAssertFalse(appState.canStartRecording)
        
        // Grant accessibility permission only (reset microphone)
        appState.setMicrophonePermission(.denied)
        appState.setAccessibilityPermission(.granted)
        XCTAssertFalse(appState.canStartRecording)
        
        // Grant both permissions
        appState.setMicrophonePermission(.granted)
        appState.setAccessibilityPermission(.granted)
        XCTAssertTrue(appState.canStartRecording)
        
        // Cannot start while recording
        appState.setRecordingState(.recording)
        XCTAssertFalse(appState.canStartRecording)
        
        // Cannot start while processing
        appState.setRecordingState(.processing)
        XCTAssertFalse(appState.canStartRecording)
    }
    
    func testRecordingStateChanges() {
        // Test recording state
        appState.setRecordingState(.recording)
        XCTAssertEqual(appState.recordingState, .recording)
        XCTAssertTrue(appState.isRecording)
        XCTAssertFalse(appState.isProcessing)
        XCTAssertNil(appState.lastError) // Error cleared when starting recording
        
        // Test processing state
        appState.setRecordingState(.processing)
        XCTAssertEqual(appState.recordingState, .processing)
        XCTAssertFalse(appState.isRecording)
        XCTAssertTrue(appState.isProcessing)
        
        // Test idle state
        appState.setRecordingState(.idle)
        XCTAssertEqual(appState.recordingState, .idle)
        XCTAssertFalse(appState.isRecording)
        XCTAssertFalse(appState.isProcessing)
    }
    
    func testErrorHandling() {
        let testError = STTError.audioDataEmpty
        
        // Set error
        appState.setError(testError)
        XCTAssertEqual(appState.lastError, testError)
        XCTAssertTrue(appState.hasError)
        
        if case .error(let error) = appState.recordingState {
            XCTAssertEqual(error, testError)
        } else {
            XCTFail("Recording state should be error")
        }
        
        // Clear error
        appState.clearError()
        XCTAssertNil(appState.lastError)
        XCTAssertFalse(appState.hasError)
        XCTAssertEqual(appState.recordingState, .idle)
    }
    
    func testErrorClearingOnRecordingStart() {
        // Set an error first
        appState.setError(.audioDataEmpty)
        XCTAssertNotNil(appState.lastError)
        
        // Start recording should clear error
        appState.setRecordingState(.recording)
        XCTAssertNil(appState.lastError)
    }
    
    func testTranscribedTextStorage() {
        let testText = "Hello world"
        appState.setLastTranscribedText(testText)
        XCTAssertEqual(appState.lastTranscribedText, testText)
    }
    
    func testPermissionUpdates() {
        // Test microphone permission
        appState.setMicrophonePermission(.requesting)
        XCTAssertEqual(appState.microphonePermission, .requesting)
        
        appState.setMicrophonePermission(.granted)
        XCTAssertEqual(appState.microphonePermission, .granted)
        
        appState.setMicrophonePermission(.denied)
        XCTAssertEqual(appState.microphonePermission, .denied)
        
        // Test accessibility permission
        appState.setAccessibilityPermission(.requesting)
        XCTAssertEqual(appState.accessibilityPermission, .requesting)
        
        appState.setAccessibilityPermission(.granted)
        XCTAssertEqual(appState.accessibilityPermission, .granted)
        
        appState.setAccessibilityPermission(.denied)
        XCTAssertEqual(appState.accessibilityPermission, .denied)
    }
}