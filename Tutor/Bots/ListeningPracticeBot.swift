//
//  ListeningPracticeBot.swift
//  Tutor
//
//  Created by Nolan Price on 8/11/25.
//

import Foundation
import SwiftOpenAI

class ListeningPracticeBot: ChatBot {
    
    private let options: Options
    
    private var initPrompt: String
    private var history: [ChatCompletionParameters.Message]
    
    init(options: Options) {
        self.options = options
        self.initPrompt = ""
        self.history = []
    }
    
    public func getInitialPrompt() async throws -> [ChatBotMessage]? {
        let systemPrompt = replaceVariables(prompt: options.listeningPracticePrompt.system)
        self.initPrompt = replaceVariables(prompt: options.listeningPracticePrompt.initialize ?? "")
        self.history = [
            .init(role: .system, content: .text(systemPrompt)),
            .init(role: .user, content: .text(initPrompt)),
        ]
        let listeningPracticeResponse = try await getListeningResponse()
        if let listeningPracticeResponse {
            return [
                ChatBotMessage(message: listeningPracticeResponse.conversation, language: options.learningLanguage.value),
                ChatBotMessage(message: listeningPracticeResponse.translation, language: options.nativeLanguage.value),
            ]
        } else {
            return nil
        }
    }
    
    public func getAnswer(for userInput: String) async throws -> [ChatBotMessage]? {
        let answer = options.listeningPracticePrompt.answer
        self.history.append(.init(role: .user, content: .text(answer)))
        guard let response = try await getListeningResponse() else { return nil }
        return [
            ChatBotMessage(message: response.conversation, language: options.learningLanguage.value),
            ChatBotMessage(message: response.translation, language: options.nativeLanguage.value),
        ]
    }
    
    private func getListeningResponse() async throws -> ListeningPracticeResponse? {
        let response = try await ChatGptClient.client.getRawResponse(messages: self.history, responseFormat: .jsonObject)
        self.history.append(.init(role: .assistant, content: .text(response)))
        return try JSONDecoder().decode(ListeningPracticeResponse.self, from: response.data(using: .utf8)!)
    }
    
    func getResponseLanguage() -> String {
        return options.learningLanguage.value
    }
    
    private func replaceVariables(prompt: String) -> String {
        return prompt.replacingOccurrences(of: "{{.NativeLanguage}", with: self.options.nativeLanguage.label)
                     .replacingOccurrences(of: "{{.LearningLanguage}}", with: self.options.learningLanguage.label)
                     .replacingOccurrences(of: "{{.Level}}", with: self.options.level)
    }
    
}
