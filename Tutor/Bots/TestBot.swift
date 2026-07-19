import Foundation
import SwiftOpenAI

class TestBot: ChatBot {
    
    private let options: Options
    
    init(options: Options) {
        self.options = options
    }
    
    public func getInitialPrompt() async throws -> [ChatBotMessage]? {
        return [
            ChatBotMessage.init(message: "おはよう。元気？", language: options.learningLanguage.value)
        ]
    }
    
    public func getAnswer(for userInput: String) async throws -> [ChatBotMessage]? {
        return [
            ChatBotMessage.init(message: "おはよう。元気？", language: options.learningLanguage.value)
        ]
    }
    
    func getResponseLanguage() -> String {
        return self.options.learningLanguage.value
    }
    
}
