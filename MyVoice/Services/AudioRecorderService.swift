import Foundation
import AVFoundation
import Combine

/// Handles audio recording for push-to-talk transcription
final class AudioRecorderService: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isRecording = false
    @Published private(set) var audioLevel: Float = 0.0
    @Published private(set) var recordingDuration: TimeInterval = 0.0
    
    // MARK: - Callbacks
    var onRecordingError: ((Error) -> Void)?
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var tempFileURL: URL?
    private var recordingStartTime: Date?
    private var durationTimer: Timer?
    
    // MARK: - Public Methods
    
    /// Start recording audio to a temporary WAV file
    func startRecording() throws -> URL {
        guard !isRecording else {
            throw RecordingError.alreadyRecording
        }
        
        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "myvoice_recording_\(UUID().uuidString).wav"
        let fileURL = tempDir.appendingPathComponent(fileName)
        self.tempFileURL = fileURL
        
        // Setup audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw RecordingError.engineSetupFailed
        }
        
        let inputNode = audioEngine.inputNode
        
        // Use a recording format that's compatible with the input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Verify we have a valid format
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            throw RecordingError.formatCreationFailed
        }
        
        // Create audio file with standard WAV format for better compatibility
        let wavSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: recordingFormat.sampleRate,
            AVNumberOfChannelsKey: 1, // Mono
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        audioFile = try AVAudioFile(forWriting: fileURL, settings: wavSettings)
        
        guard let outputFormat = audioFile?.processingFormat else {
            throw RecordingError.formatCreationFailed
        }
        
        // Create converter from input format to file format
        guard let converter = AVAudioConverter(from: recordingFormat, to: outputFormat) else {
            throw RecordingError.converterCreationFailed
        }
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, converter: converter, outputFormat: outputFormat)
        }
        
        // Prepare and start engine
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        recordingStartTime = Date()
        startDurationTimer()
        
        return fileURL
    }
    
    /// Stop recording and return the file URL
    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        
        stopDurationTimer()
        
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        
        isRecording = false
        audioLevel = 0.0
        
        return tempFileURL
    }
    
    /// Delete the temporary recording file
    func deleteRecordingFile() {
        guard let url = tempFileURL else { return }
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            tempFileURL = nil
        } catch {
            print("Failed to delete recording file: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, converter: AVAudioConverter, outputFormat: AVAudioFormat) {
        // Calculate audio level for visual feedback
        updateAudioLevel(from: buffer)
        
        // Calculate output frame count based on sample rate ratio
        let sampleRateRatio = outputFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * sampleRateRatio)
        
        guard outputFrameCount > 0 else { return }
        
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount) else {
            return
        }
        
        // Use a flag to track if we've consumed the input
        var inputConsumed = false
        
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputConsumed = true
            outStatus.pointee = .haveData
            return buffer
        }
        
        var error: NSError?
        let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
        
        guard status != .error, error == nil else {
            if let error = error {
                print("Conversion error: \(error.localizedDescription)")
            }
            return
        }
        
        // Only write if we have data
        guard convertedBuffer.frameLength > 0 else { return }
        
        do {
            try audioFile?.write(from: convertedBuffer)
        } catch {
            print("Write error: \(error.localizedDescription)")
        }
    }
    
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        
        // Calculate RMS
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))
        
        // Convert to dB
        let db = 20 * log10(max(rms, 0.000001))
        
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = db
        }
    }
    
    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            DispatchQueue.main.async {
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
        recordingDuration = 0.0
    }
}

// MARK: - Errors
extension AudioRecorderService {
    enum RecordingError: LocalizedError {
        case alreadyRecording
        case engineSetupFailed
        case formatCreationFailed
        case converterCreationFailed
        case fileCreationFailed
        
        var errorDescription: String? {
            switch self {
            case .alreadyRecording:
                return "Recording is already in progress"
            case .engineSetupFailed:
                return "Failed to setup audio engine"
            case .formatCreationFailed:
                return "Failed to create audio format"
            case .converterCreationFailed:
                return "Failed to create audio converter"
            case .fileCreationFailed:
                return "Failed to create audio file"
            }
        }
    }
}
