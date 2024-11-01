import SwiftUI
import AVFoundation
import SwiftOpenAI

class AudioTranscriber: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var chatGptClient = ChatGptClient()
    
    @Published var isRecording = false;
    @Published var transcribedAudio = ""
    @Published var isTranscribing = false;
    
    public func startRecording() async {
        if (isTranscribing) {
            return
        }
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Request permission to record.
        if await AVAudioApplication.requestRecordPermission() {
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
            do {
                self.audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
                self.audioRecorder?.record()
                DispatchQueue.main.async {
                    self.isRecording = true
                }
            } catch {
                print("Failed to start recording: \(error.localizedDescription)")
            }
        } else {
            print("Permission not granted")
        }
    }
    
    public func stopRecording() {
        self.audioRecorder?.stop()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    public func transcribeAudio(language: String) async -> Void {
        guard let fileURL = audioRecorder?.url else {
            return
        }
        DispatchQueue.main.async {
            self.isTranscribing = true
            self.transcribedAudio = "Transcribing..."
        }
        do {
            let response = try await chatGptClient.speechToText(fileUrl: fileURL, language: language) ?? "Failed to transcribe audio"
            DispatchQueue.main.async {
                self.transcribedAudio = response
                self.isTranscribing = false	
            }
        } catch APIError.responseUnsuccessful(let description, let statusCode) {
            DispatchQueue.main.async {
                self.transcribedAudio = "OpenAI Error: status=\(statusCode) error=\(description)"
                self.isTranscribing = false
            }
        } catch {
            DispatchQueue.main.async {
                self.transcribedAudio = "Unknown error \(error)"
                self.isTranscribing = false
            }
        }
    }
}
