import SwiftOpenAI
import Foundation

class ConversationBot: ChatBot {
    
    private let options: Options
    
    private var history: [ChatCompletionParameters.Message]
    private var setup: String?
    private var persona: String?
    private var lastTutorMessage: String?
    
    init(options: Options) {
        self.options = options
        self.history = []
    }
    
    public func getInitialPrompt() async throws -> [ChatBotMessage]? {
        let systemPrompt = replaceVariables(prompt: self.options.conversationPrompt.system)
        let initPrompt = replaceVariables(prompt: self.options.conversationPrompt.initialize ?? "")
        self.history = [
            .init(role: .system, content: .text(systemPrompt)),
            .init(role: .user, content: .text(initPrompt)),
        ]
        guard let response = try await getConversationTopicResponse() else { return nil }
        self.setup = response.setup
        self.persona = response.persona
        self.lastTutorMessage = response.opening
        return [
            ChatBotMessage(message: response.setup, language: options.nativeLanguage.value),
            ChatBotMessage(message: response.persona, language: options.nativeLanguage.value),
            ChatBotMessage(message: response.opening, language: options.learningLanguage.value)
        ]
    }
    
    public func getAnswer(for userInput: String) async throws -> [ChatBotMessage]? {
        guard let analysisResponse = try await getAnalysisResponse(for: userInput) else { return nil }
        if analysisResponse.classification != "NATURAL" {
            return [
                ChatBotMessage(message: analysisResponse.feedback, language: options.nativeLanguage.value),
                ChatBotMessage(message: analysisResponse.correction, language: options.nativeLanguage.value),
            ]
        }
        let answer = replaceVariables(prompt: self.options.conversationPrompt.answer, answer: userInput)
        self.history.append(.init(role: .user, content: .text(answer)))
        guard let response = try await getResponse() else { return nil }
        self.lastTutorMessage = response
        return [
            ChatBotMessage(message: response, language: options.learningLanguage.value),
        ]
    }
    
    private func getAnalysisResponse(for userInput: String) async throws -> ConversationAnalysisResponse? {
        let analysis = replaceVariables(prompt: self.options.conversationAnalysisPrompt, answer: userInput)
        let newHistory = self.history + [ .init(role: .user, content: .text(analysis)) ];
        let response = try await ChatGptClient.client.getRawResponse(messages: newHistory, responseFormat: .jsonObject)
        return try JSONDecoder().decode(ConversationAnalysisResponse.self, from: response.data(using: .utf8)!)
    }
    
    private func getResponse() async throws -> String? {
        let response = try await ChatGptClient.client.getRawResponse(messages: self.history, responseFormat: .text)
        self.history.append(.init(role: .assistant, content: .text(response)))
        return response
    }
    
    func getResponseLanguage() -> String {
        return self.options.learningLanguage.value
    }
    
    private func getConversationTopicResponse() async throws -> ConversationTopicResponse? {
        let response = try await ChatGptClient.client.getRawResponse(messages: self.history, responseFormat: .jsonObject)
        self.history.append(.init(role: .assistant, content: .text(response)))
        return try JSONDecoder().decode(ConversationTopicResponse.self, from: response.data(using: .utf8)!)
    }
    
    private func replaceVariables(prompt: String) -> String {
        return replaceVariables(prompt: prompt, answer: nil)
    }
    
    private func replaceVariables(prompt: String, answer: String?) -> String {
        return prompt.replacingOccurrences(of: "{{.LearningLanguage}", with: self.options.learningLanguage.label)
                     .replacingOccurrences(of: "{{.NativeLanguage}", with: self.options.nativeLanguage.label)
                     .replacingOccurrences(of: "{{.Level}}", with: self.options.level)
                     .replacingOccurrences(of: "{{.Answer}}", with: answer ?? "")
                     .replacingOccurrences(of: "{{.Setup}}", with: setup ?? "")
                     .replacingOccurrences(of: "{{.Persona}}", with: persona ?? "")
                     .replacingOccurrences(of: "{{.LastTutorMessage}}", with: lastTutorMessage ?? "")
    }
    
}
