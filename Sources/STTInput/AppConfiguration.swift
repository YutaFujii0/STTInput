import Foundation

/// Centralized configuration management for the application
struct AppConfiguration {
    
    // MARK: - Recording Configuration
    
    /// Maximum recording duration in seconds
    let maxRecordingDuration: TimeInterval
    
    /// Minimum recording duration in seconds
    let minRecordingDuration: TimeInterval
    
    /// Audio sample rate for recording
    let audioSampleRate: Double
    
    // MARK: - UI Configuration
    
    /// Minimum time to display processing indicator
    let minProcessingDisplayTime: TimeInterval
    
    /// Delay before showing processing indicator
    let processingIndicatorDelay: TimeInterval
    
    /// Status indicator auto-hide duration
    let statusIndicatorDuration: TimeInterval
    
    // MARK: - Service Configuration
    
    /// OpenAI API key (loaded from keychain)
    let apiKey: String?
    
    /// Network request timeout
    let networkTimeout: TimeInterval
    
    /// Maximum retry attempts for API calls
    let maxRetryAttempts: Int
    
    // MARK: - Accessibility Configuration
    
    /// Delay after app launch before starting services (allows permissions to be granted)
    let serviceStartDelay: TimeInterval
    
    /// Whether to play audio feedback on recording start/stop
    let audioFeedbackEnabled: Bool
    
    // MARK: - Default Configuration
    
    static let `default` = AppConfiguration(
        maxRecordingDuration: 30.0,
        minRecordingDuration: 0.5,
        audioSampleRate: 44100.0,
        minProcessingDisplayTime: 0.8,
        processingIndicatorDelay: 0.1,
        statusIndicatorDuration: 2.0,
        apiKey: nil, // Will be loaded from keychain
        networkTimeout: 30.0,
        maxRetryAttempts: 3,
        serviceStartDelay: 2.0,
        audioFeedbackEnabled: true
    )
    
    // MARK: - Configuration Loading
    
    /// Loads configuration with API key from keychain
    static func load() -> AppConfiguration {
        var config = AppConfiguration.default
        
        // Load API key from keychain
        if let apiKey = loadApiKeyFromKeychain() {
            config = AppConfiguration(
                maxRecordingDuration: config.maxRecordingDuration,
                minRecordingDuration: config.minRecordingDuration,
                audioSampleRate: config.audioSampleRate,
                minProcessingDisplayTime: config.minProcessingDisplayTime,
                processingIndicatorDelay: config.processingIndicatorDelay,
                statusIndicatorDuration: config.statusIndicatorDuration,
                apiKey: apiKey,
                networkTimeout: config.networkTimeout,
                maxRetryAttempts: config.maxRetryAttempts,
                serviceStartDelay: config.serviceStartDelay,
                audioFeedbackEnabled: config.audioFeedbackEnabled
            )
        }
        
        return config
    }
    
    // MARK: - Validation
    
    /// Validates the current configuration
    var isValid: Bool {
        return validationErrors.isEmpty
    }
    
    /// Returns validation errors if configuration is invalid
    var validationErrors: [String] {
        var errors: [String] = []
        
        if maxRecordingDuration <= minRecordingDuration {
            errors.append("Maximum recording duration must be greater than minimum")
        }
        
        if minRecordingDuration <= 0 {
            errors.append("Minimum recording duration must be positive")
        }
        
        if audioSampleRate <= 0 {
            errors.append("Audio sample rate must be positive")
        }
        
        if networkTimeout <= 0 {
            errors.append("Network timeout must be positive")
        }
        
        if maxRetryAttempts <= 0 {
            errors.append("Max retry attempts must be positive")
        }
        
        // Note: API key can be nil in default configuration since it's loaded separately
        // Only validate if it's explicitly set to empty string
        if apiKey == "" {
            errors.append("API key is required")
        }
        
        return errors
    }
}

// MARK: - Private Helpers

private extension AppConfiguration {
    
    static func loadApiKeyFromKeychain() -> String? {
        // This would integrate with the existing KeychainHelper
        // For now, return nil to indicate it should be loaded by WhisperClient
        return nil
    }
}

// MARK: - Environment-based Configuration

extension AppConfiguration {
    
    /// Development configuration with more lenient settings
    static let development = AppConfiguration(
        maxRecordingDuration: 60.0, // Longer for testing
        minRecordingDuration: 0.1,  // Shorter for testing
        audioSampleRate: 44100.0,
        minProcessingDisplayTime: 0.3, // Shorter for faster development
        processingIndicatorDelay: 0.05,
        statusIndicatorDuration: 1.0,
        apiKey: nil,
        networkTimeout: 10.0, // Shorter timeout for faster feedback
        maxRetryAttempts: 1,   // Fewer retries for faster failure
        serviceStartDelay: 1.0, // Shorter delay
        audioFeedbackEnabled: true
    )
    
    /// Production configuration with optimal settings
    static let production = AppConfiguration(
        maxRecordingDuration: 30.0,
        minRecordingDuration: 0.5,
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
}