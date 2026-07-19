import Foundation
import SwiftOpenAI

class PhraseBot: ChatBot {
    
    private let options: Options
    
    init(options: Options) {
        self.options = options
    }
    
    public func getInitialPrompt() async throws -> [ChatBotMessage]? {
        return nil
    }
    
    public func getAnswer(for userInput: String) async throws -> [ChatBotMessage]? {
        let answer = self.options.phraseCorrectionPrompt.answer.replacingOccurrences(of: "{{.Answer}}", with: userInput)
        let systemPrompt = replaceVariables(prompt: options.phraseCorrectionPrompt.system)
        let history: [ChatCompletionParameters.Message] = [
            .init(role: .system, content: .text(systemPrompt)),
            .init(role: .user, content: .text(answer))
        ]
        let response = try await ChatGptClient.client.getRawResponse(messages: history, responseFormat: .text)
        return [ ChatBotMessage(message: response, language: options.nativeLanguage.value) ]
    }
    
    func getResponseLanguage() -> String {
        return self.options.learningLanguage.value
    }
    
    private func replaceVariables(prompt: String) -> String {
        return prompt.replacingOccurrences(of: "{{.NativeLanguage}", with: self.options.nativeLanguage.label)
                     .replacingOccurrences(of: "{{.LearningLanguage}}", with: self.options.learningLanguage.label)
                     .replacingOccurrences(of: "{{.Level}}", with: self.options.level)
    }
    
}
