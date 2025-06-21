import Foundation

public class WhisperClient {
    private let apiKey: String
    private let apiURL = "https://api.openai.com/v1/audio/transcriptions"
    private let session = URLSession.shared
    
    public init() {
        self.apiKey = WhisperClient.getAPIKey()
    }
    
    public func transcribe(audioData: Data) async throws -> String {
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WhisperError.apiError("Invalid response")
        }
        
        let transcriptionResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return transcriptionResponse.text
    }
    
    private static func getAPIKey() -> String {
        // First try to get from Keychain
        if let apiKey = KeychainHelper.shared.get("OpenAI_API_Key") {
            return apiKey
        }
        
        // Fallback to environment variable
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return apiKey
        }
        
        // Fallback to .env file
        if let apiKey = loadFromEnvFile() {
            return apiKey
        }
        
        return ""
    }
    
    private static func loadFromEnvFile() -> String? {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let envURL = homeURL.appendingPathComponent(".sttinput.env")
        
        guard let contents = try? String(contentsOf: envURL) else { return nil }
        
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count == 2 && parts[0] == "OPENAI_API_KEY" {
                return parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
}

struct TranscriptionResponse: Codable {
    let text: String
}

enum WhisperError: LocalizedError {
    case apiError(String)
    case noAPIKey
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "API Error: \(message)"
        case .noAPIKey:
            return "No OpenAI API key found"
        }
    }
}