import SwiftUI
import AVFoundation
import SwiftOpenAI

class AudioTranscriber: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var silenceTimer: DispatchSourceTimer?
    private var audioLevelTimer: DispatchSourceTimer?
    private let silenceThreshold: TimeInterval = 3.0 // Stop after 3 seconds of silence
    private let audioLevelThreshold: Float = -40.0 // dB threshold for silence detection
    
    @Published var isRecording = false;
    @Published var transcribedAudio = ""
    @Published var isTranscribing = false;
    
    public func startRecording(language: String) async {
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
                playBeep()
                self.audioRecorder?.record()
                startSilenceDetection(language: language)
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
        playBeep()
        stopSilenceDetection()
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
            let response = try await ChatGptClient.client.speechToText(fileUrl: fileURL, language: language) ?? "Failed to transcribe audio"
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
    
    private func playBeep() {
        // Option 1: Use system sound
        AudioServicesPlaySystemSound(1113) // This is a beep sound
        
        // Option 2: Or create a custom beep tone (more advanced)
        // playCustomBeep()
    }
        
    private func startSilenceDetection(language: String) {
        stopSilenceDetection()
        
        // Enable audio level monitoring on your recorder
        // This assumes you're using AVAudioRecorder
        audioRecorder?.isMeteringEnabled = true
        
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: 0.1)
        timer.setEventHandler { [weak self] in
            self?.checkAudioLevel(language: language)
        }
        timer.resume()
        
        audioLevelTimer = timer
        print("Started dispatch timer for audio level monitoring")
    }
    
    private func checkAudioLevel(language: String) {
        print("Checking audio level...") // Debug log
        
        guard let recorder = audioRecorder, recorder.isRecording else {
            print("No recorder or not recording")
            return
        }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        
        print("Audio level: \(averagePower)") // Debug log
        
        if averagePower < audioLevelThreshold {
            // Sound level is below threshold (silence detected)
            if silenceTimer == nil {
                startSilenceTimer(language: language)
            }
        } else {
            // Sound detected, cancel silence timer
            cancelSilenceTimer()
        }
    }
    
    private func startSilenceTimer(language: String) {
        print("Starting silence timer...")
        
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + silenceThreshold)
        timer.setEventHandler { [weak self] in
            print("Silence timeout reached - stopping recording")
            self?.handleSilenceTimeout(language: language)
        }
        timer.resume()
        
        silenceTimer = timer
    }
    
    private func cancelSilenceTimer() {
        if silenceTimer != nil {
            print("Canceling silence timer - sound detected")
        }
        silenceTimer?.cancel()
        silenceTimer = nil
    }
    
    private func handleSilenceTimeout(language: String) {
        silenceTimer?.cancel()
        silenceTimer = nil
        
        // Stop recording and start transcription
        stopRecording()
        Task {
            await transcribeAudio(language: language)
        }
    }
    
    private func stopSilenceDetection() {
        audioLevelTimer?.cancel()
        audioLevelTimer = nil
        silenceTimer?.cancel()
        silenceTimer = nil
    }
}
