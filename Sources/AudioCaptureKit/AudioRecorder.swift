import AVFoundation
import Foundation

public class AudioRecorder: NSObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var recordingTimer: Timer?
    private let maxRecordingDuration: TimeInterval = 120.0
    private var recordingCompletion: ((Data) -> Void)?
    
    @Published public var isRecording = false
    
    public override init() {
        super.init()
    }
    
    public func startRecording(completion: @escaping (Data) -> Void) {
        guard !isRecording else { return }
        
        recordingCompletion = completion
        
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            if granted {
                DispatchQueue.main.async {
                    self?.setupAndStartRecording()
                }
            } else {
                print("Microphone access denied")
            }
        }
    }
    
    private func setupAndStartRecording() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode!.outputFormat(forBus: 0)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        
        do {
            audioFile = try AVAudioFile(forWriting: outputURL, settings: recordingFormat.settings)
            
            inputNode!.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                do {
                    try self?.audioFile?.write(from: buffer)
                } catch {
                    print("Error writing buffer: \(error)")
                }
            }
            
            try audioEngine.start()
            isRecording = true
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { [weak self] _ in
                self?.stopRecording()
            }
        } catch {
            print("Error starting recording: \(error)")
        }
    }
    
    public func stopRecording() {
        guard isRecording else { return }
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        
        isRecording = false
        
        if let audioFile = audioFile {
            do {
                let data = try Data(contentsOf: audioFile.url)
                recordingCompletion?(data)
            } catch {
                print("Error reading audio file: \(error)")
            }
            
            try? FileManager.default.removeItem(at: audioFile.url)
        }
        
        audioEngine = nil
        audioFile = nil
    }
}