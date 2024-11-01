//
//  Tools.swift
//  Tutor
//
//  Created by Nolan Price on 9/18/24.
//

import Foundation
import SwiftOpenAI
import AVFoundation

class Tools {
    
    private let client: ChatGptClient
    private let options: Options
    private var audioPlayer: AVAudioPlayer?
    
    init(options: Options) {
        self.client = ChatGptClient()
        self.options = options
        self.audioPlayer = nil
    }
    
    func translate(text: String) async throws -> String? {
        let prompt = replaceVariables(prompt: self.options.translatePrompt, text: text)
        let message: ChatCompletionParameters.Message = .init(role: .system, content: .text(prompt))
        return try await client.getRawResponse(messages: [message], responseFormat: .text)
    }
    
    func writeInHiragana(text: String) async throws -> String? {
        let prompt = replaceVariables(prompt: self.options.hiraganaPrompt, text: text)
        let message: ChatCompletionParameters.Message = .init(role: .system, content: .text(prompt))
        return try await client.getRawResponse(messages: [message], responseFormat: .text)
    }
    
    func textToSpeech(text: String) async -> Void {
        if (isPlayingAudio()) {
            return
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try? audioSession.setCategory(.playAndRecord, mode: .default, policy: .default, options: .defaultToSpeaker)
            
            let data = try await client.textToSpeech(text: text)
            // Initialize the audio player with the data
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            // Handle errors
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func replayAudio() -> Void {
        if (isPlayingAudio()) {
            return
        }
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
    
    func isAudioLoaded() -> Bool {
        return audioPlayer != nil
    }
    
    func isPlayingAudio() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
 
    private func replaceVariables(prompt: String, text: String) -> String {
        return prompt.replacingOccurrences(of: "{{.Text}", with: text)
            .replacingOccurrences(of: "{{.Language}}", with: self.options.nativeLanguage.label)
    }
    
    
}
