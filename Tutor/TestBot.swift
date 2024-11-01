import Foundation
import SwiftOpenAI

class TestBot: ChatBot {
    
    private let options: Options
    
    init(options: Options) {
        self.options = options
    }
    
    public func getInitialPrompt() async throws -> String? {
        return """
        First message.
        """
    }
    
    public func getAnswer(for userInput: String) async throws -> [String]? {
        return [
            """
            Second message.
            """
        ]
    }
    
    func getResponseLanguage() -> String {
        return self.options.learningLanguage.value
    }
    
}
