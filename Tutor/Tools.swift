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
    
    private let options: Options
    private var audioPlayer: AVAudioPlayer?
    
    init(options: Options) {
        self.options = options
        self.audioPlayer = nil
    }
    
    func translate(text: String) async throws -> String {
        return try await GoogleClient.client.translate(text: text, language: options.nativeLanguage.value)
    }
    
    func translate_chatGpt(text: String) async throws -> String? {
        let prompt = replaceVariables(prompt: self.options.translatePrompt, text: text)
        let message: ChatCompletionParameters.Message = .init(role: .system, content: .text(prompt))
        return try await ChatGptClient.client.getRawResponse(messages: [message], responseFormat: .text)
    }
    
    func writeInHiragana(text: String) async throws -> String? {
        let prompt = replaceVariables(prompt: self.options.hiraganaPrompt, text: text)
        let message: ChatCompletionParameters.Message = .init(role: .system, content: .text(prompt))
        return try await ChatGptClient.client.getRawResponse(messages: [message], responseFormat: .text)
    }
    
    func getTokenizedResponse(response: String) async throws -> [TokenizedWord]? {
        let prompt = self.options.tokenizePrompt.replacingOccurrences(of: "{{.Input}}", with: response)
        let messages: [ChatCompletionParameters.Message] = [
            .init(role: .user, content: .text(prompt)),
        ]
        let tokenizedResponse = try await ChatGptClient.client.getRawResponse(messages:messages, responseFormat: .jsonObject)
        return try JSONDecoder().decode(TokenizedWordsResponse.self, from: tokenizedResponse.data(using: .utf8)!).words
    }
 
    private func replaceVariables(prompt: String, text: String) -> String {
        return prompt.replacingOccurrences(of: "{{.Text}", with: text)
                     .replacingOccurrences(of: "{{.LearningLanguage}}", with: self.options.learningLanguage.label)
                     .replacingOccurrences(of: "{{.NativeLanguage}}", with: self.options.nativeLanguage.label)
    }
    
    
}
