import Foundation
import os.log

/// Simple logger for STTInput that ensures output is visible in logs
struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "STTInput"
    private static let osLog = OSLog(subsystem: subsystem, category: "main")
    
    static func log(_ message: String, type: OSLogType = .default) {
        // Log to both stdout and os_log
        print("[\(Date())] \(message)")
        
        // Also log to system log
        os_log("%{public}@", log: osLog, type: type, message)
    }
    
    static func debug(_ message: String) {
        log("DEBUG: \(message)", type: .debug)
    }
    
    static func info(_ message: String) {
        log("INFO: \(message)", type: .info)
    }
    
    static func error(_ message: String) {
        log("ERROR: \(message)", type: .error)
    }
}