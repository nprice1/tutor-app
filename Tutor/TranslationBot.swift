import Foundation
import SwiftOpenAI

enum TranslationType {
    case nativeToLearning
    case learningToNative
}

class TranslationBot: ChatBot {
    
    private let client: ChatGptClient
    private let options: Options
    private let type: TranslationType
    
    private var initPrompt: String
    private var history: [ChatCompletionParameters.Message]
    private var currentExercise: String
    
    init(type: TranslationType, options: Options) {
        self.client = ChatGptClient()
        self.type = type
        self.options = options
        self.initPrompt = ""
        self.history = []
        self.currentExercise = ""
    }
    
    public func getInitialPrompt() async throws -> String? {
        let systemPrompt = replaceVariables(prompt: options.translationPrompt.system)
        self.initPrompt = replaceVariables(prompt: options.translationPrompt.initialize ?? "")
        self.history = [
            .init(role: .system, content: .text(systemPrompt)),
            .init(role: .user, content: .text(initPrompt)),
        ]
        let translationPrompt = try await getTranslationResponse()
        if let translationPrompt {
            self.currentExercise = translationPrompt.exercise ?? ""
            return translationPrompt.exercise
        } else {
            return nil
        }
    }
    
    public func getAnswer(for userInput: String) async throws -> [String]? {
        let answer = options.translationPrompt.answer.replacingOccurrences(of: "{{.Exercise}}", with: self.currentExercise).replacingOccurrences(of: "{{.Answer}}", with: userInput)
        self.history.append(.init(role: .user, content: .text(answer)))
        // Get the correction for the users answer
        guard let correction = try await getTranslationResponse() else { return nil }
        // Ask for the next exercise
        self.history.append(.init(role: .user, content: .text(self.initPrompt)))
        guard let newExercise = try await getTranslationResponse() else { return nil }
        self.currentExercise = newExercise.exercise ?? ""
        return [
            correction.correction ?? "",
            correction.explanation ?? "",
            newExercise.exercise ?? ""
        ]
    }
    
    func getResponseLanguage() -> String {
        return self.type == .learningToNative ? self.options.nativeLanguage.value : self.options.learningLanguage.value
    }
    
    private func getTranslationResponse() async throws -> TranslationPrompt? {
        guard let response = try await self.client.getRawResponse(messages: self.history, responseFormat: .jsonObject) else { return nil }
        self.history.append(.init(role: .assistant, content: .text(response)))
        return try JSONDecoder().decode(TranslationPrompt.self, from: response.data(using: .utf8)!)
    }
    
    private func replaceVariables(prompt: String) -> String {
        let fromLanguage = self.type == .nativeToLearning ? self.options.nativeLanguage.label : self.options.learningLanguage.label
        let toLanguage = self.type == .nativeToLearning ? self.options.learningLanguage.label : self.options.nativeLanguage.label
        return prompt.replacingOccurrences(of: "{{.FromLanguage}", with: fromLanguage)
                     .replacingOccurrences(of: "{{.ToLanguage}}", with: toLanguage)
                     .replacingOccurrences(of: "{{.Level}}", with: self.options.level)
    }
    
}
