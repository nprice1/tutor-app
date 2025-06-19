//
//  ToolsStatic.swift
//  Tutor
//
//  Created by Nolan Price on 12/5/24.
//

import Foundation
import AVFoundation

class AudioSpeaker: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    private var audioPlayer: AVAudioPlayer?
    @Published public var isPlaying = false
    
    func textToSpeech(options: Options, text: String) async -> Void {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, policy: .default, options: .defaultToSpeaker)
            
            let data = try await GoogleClient.client.textToSpeech(text: text, language: options.learningLanguage.value)
            // Initialize the audio player with the data
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            // Handle errors
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func stopAudio() -> Void {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    func replayAudio() -> Void {
        if (isPlaying) {
            return
        }
        audioPlayer?.play()
        isPlaying = true
    }
    
    func isAudioLoaded() -> Bool {
        return audioPlayer != nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
    
}
