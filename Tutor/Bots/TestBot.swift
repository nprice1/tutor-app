import Foundation
import SwiftOpenAI

class TestBot: ChatBot {
    
    private let options: Options
    
    init(options: Options) {
        self.options = options
    }
    
    public func getInitialPrompt() async throws -> String? {
        return """
        おはよう。元気？
        """
    }
    
    public func getAnswer(for userInput: String) async throws -> [String]? {
        return [
            """
            おはよう。元気？
            """
        ]
    }
    
    func getResponseLanguage() -> String {
        return self.options.learningLanguage.value
    }
    
}
