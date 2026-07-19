import Foundation
import SwiftOpenAI

class QuizBot: ChatBot {
    
    private let options: Options
    
    private var initPrompt: String
    private var history: [ChatCompletionParameters.Message]
    private var currentExercise: String
    
    init(options: Options) {
        self.options = options
        self.initPrompt = ""
        self.history = []
        self.currentExercise = ""
    }
    
    public func getInitialPrompt() async throws -> [ChatBotMessage]? {
        let systemPrompt = replaceVariables(prompt: options.quizPrompt.system)
        self.initPrompt = replaceVariables(prompt: options.quizPrompt.initialize ?? "")
        self.history = [
            .init(role: .system, content: .text(systemPrompt)),
            .init(role: .user, content: .text(initPrompt)),
        ]
        guard let response = try await getResponse() else { return nil }
        return [ ChatBotMessage(message: response, language: options.nativeLanguage.value) ]
    }
    
    public func getAnswer(for userInput: String) async throws -> [ChatBotMessage]? {
        let answer = self.options.quizPrompt.answer.replacingOccurrences(of: "{{.Answer}}", with: userInput)
        self.history.append(.init(role: .user, content: .text(answer)))
        guard let response = try await getResponse() else { return nil }
        return [ ChatBotMessage(message: response, language: options.learningLanguage.value) ]
    }
    
    func getResponseLanguage() -> String {
        return self.options.learningLanguage.value
    }
    
    private func getResponse() async throws -> String? {
        let response = try await ChatGptClient.client.getRawResponse(messages: self.history, responseFormat: .text)
        self.history.append(.init(role: .assistant, content: .text(response)))
        return response
    }
    
    private func replaceVariables(prompt: String) -> String {
        return prompt.replacingOccurrences(of: "{{.NativeLanguage}", with: self.options.nativeLanguage.label)
                     .replacingOccurrences(of: "{{.LearningLanguage}}", with: self.options.learningLanguage.label)
                     .replacingOccurrences(of: "{{.Level}}", with: self.options.level)
    }
    
}
