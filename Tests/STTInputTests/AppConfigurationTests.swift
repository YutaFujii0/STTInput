import XCTest
@testable import STTInput

final class AppConfigurationTests: XCTestCase {
    
    func testDefaultConfiguration() {
        let config = AppConfiguration.default
        
        XCTAssertEqual(config.maxRecordingDuration, 30.0)
        XCTAssertEqual(config.minRecordingDuration, 0.5)
        XCTAssertEqual(config.audioSampleRate, 44100.0)
        XCTAssertEqual(config.minProcessingDisplayTime, 0.8)
        XCTAssertEqual(config.processingIndicatorDelay, 0.1)
        XCTAssertEqual(config.statusIndicatorDuration, 2.0)
        XCTAssertNil(config.apiKey)
        XCTAssertEqual(config.networkTimeout, 30.0)
        XCTAssertEqual(config.maxRetryAttempts, 3)
        XCTAssertEqual(config.serviceStartDelay, 2.0)
        XCTAssertTrue(config.audioFeedbackEnabled)
    }
    
    func testDevelopmentConfiguration() {
        let config = AppConfiguration.development
        
        // Development should have more lenient settings
        XCTAssertEqual(config.maxRecordingDuration, 60.0) // Longer for testing
        XCTAssertEqual(config.minRecordingDuration, 0.1)  // Shorter for testing
        XCTAssertEqual(config.minProcessingDisplayTime, 0.3) // Shorter for faster development
        XCTAssertEqual(config.networkTimeout, 10.0) // Shorter timeout
        XCTAssertEqual(config.maxRetryAttempts, 1)   // Fewer retries
        XCTAssertEqual(config.serviceStartDelay, 1.0) // Shorter delay
    }
    
    func testProductionConfiguration() {
        let config = AppConfiguration.production
        
        // Production should match default settings
        XCTAssertEqual(config.maxRecordingDuration, 30.0)
        XCTAssertEqual(config.minRecordingDuration, 0.5)
        XCTAssertEqual(config.minProcessingDisplayTime, 0.8)
        XCTAssertEqual(config.networkTimeout, 30.0)
        XCTAssertEqual(config.maxRetryAttempts, 3)
        XCTAssertEqual(config.serviceStartDelay, 2.0)
    }
    
    func testValidConfiguration() {
        let validConfig = AppConfiguration.default
        XCTAssertTrue(validConfig.isValid)
        XCTAssertTrue(validConfig.validationErrors.isEmpty)
    }
    
    func testInvalidConfiguration() {
        // Test with invalid max/min recording duration
        let invalidConfig1 = AppConfiguration(
            maxRecordingDuration: 1.0,
            minRecordingDuration: 2.0, // Min > Max
            audioSampleRate: 44100.0,
            minProcessingDisplayTime: 0.8,
            processingIndicatorDelay: 0.1,
            statusIndicatorDuration: 2.0,
            apiKey: nil,
            networkTimeout: 30.0,
            maxRetryAttempts: 3,
            serviceStartDelay: 2.0,
            audioFeedbackEnabled: true
        )
        
        XCTAssertFalse(invalidConfig1.isValid)
        XCTAssertTrue(invalidConfig1.validationErrors.contains("Maximum recording duration must be greater than minimum"))
        
        // Test with negative values
        let invalidConfig2 = AppConfiguration(
            maxRecordingDuration: 30.0,
            minRecordingDuration: -1.0, // Negative
            audioSampleRate: -44100.0, // Negative
            minProcessingDisplayTime: 0.8,
            processingIndicatorDelay: 0.1,
            statusIndicatorDuration: 2.0,
            apiKey: nil,
            networkTimeout: -30.0, // Negative
            maxRetryAttempts: -3, // Negative
            serviceStartDelay: 2.0,
            audioFeedbackEnabled: true
        )
        
        XCTAssertFalse(invalidConfig2.isValid)
        let errors = invalidConfig2.validationErrors
        XCTAssertTrue(errors.contains("Minimum recording duration must be positive"))
        XCTAssertTrue(errors.contains("Audio sample rate must be positive"))
        XCTAssertTrue(errors.contains("Network timeout must be positive"))
        XCTAssertTrue(errors.contains("Max retry attempts must be positive"))
        
        // Test with missing API key (empty string)
        let invalidConfig3 = AppConfiguration(
            maxRecordingDuration: 30.0,
            minRecordingDuration: 0.5,
            audioSampleRate: 44100.0,
            minProcessingDisplayTime: 0.8,
            processingIndicatorDelay: 0.1,
            statusIndicatorDuration: 2.0,
            apiKey: "", // Empty API key
            networkTimeout: 30.0,
            maxRetryAttempts: 3,
            serviceStartDelay: 2.0,
            audioFeedbackEnabled: true
        )
        
        XCTAssertFalse(invalidConfig3.isValid)
        XCTAssertTrue(invalidConfig3.validationErrors.contains("API key is required"))
    }
    
    func testConfigurationLoad() {
        // Since loadApiKeyFromKeychain returns nil in our implementation,
        // load() should return the default configuration
        let loadedConfig = AppConfiguration.load()
        
        // Should match default except potentially for API key
        XCTAssertEqual(loadedConfig.maxRecordingDuration, AppConfiguration.default.maxRecordingDuration)
        XCTAssertEqual(loadedConfig.minRecordingDuration, AppConfiguration.default.minRecordingDuration)
        XCTAssertEqual(loadedConfig.audioSampleRate, AppConfiguration.default.audioSampleRate)
        XCTAssertEqual(loadedConfig.networkTimeout, AppConfiguration.default.networkTimeout)
        XCTAssertEqual(loadedConfig.maxRetryAttempts, AppConfiguration.default.maxRetryAttempts)
    }
    
    func testConfigurationBoundaryValues() {
        // Test with zero values where appropriate
        let zeroConfig = AppConfiguration(
            maxRecordingDuration: 0.1,
            minRecordingDuration: 0.0, // Zero should be invalid
            audioSampleRate: 44100.0,
            minProcessingDisplayTime: 0.0, // Zero should be valid
            processingIndicatorDelay: 0.0, // Zero should be valid
            statusIndicatorDuration: 2.0,
            apiKey: "test-key",
            networkTimeout: 0.1,
            maxRetryAttempts: 1,
            serviceStartDelay: 0.0, // Zero should be valid
            audioFeedbackEnabled: true
        )
        
        XCTAssertFalse(zeroConfig.isValid)
        XCTAssertTrue(zeroConfig.validationErrors.contains("Minimum recording duration must be positive"))
    }
}