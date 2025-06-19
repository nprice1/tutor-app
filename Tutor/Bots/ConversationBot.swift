import SwiftOpenAI

class ConversationBot: ChatBot {

    private let options: Options
    private let persona: String
    private let place: String
    private let topic: String
    
    private var history: [ChatCompletionParameters.Message]
    
    init(options: Options, persona: String, place: String, topic: String) {
        self.options = options
        self.persona = persona
        self.place = place
        self.topic = topic
        self.history = []
    }
    
    public func getInitialPrompt() async throws -> String? {
        let systemPrompt = replaceVariables(prompt: self.options.conversationPrompt.system)
        let initPrompt = replaceVariables(prompt: self.options.conversationPrompt.initialize ?? "")
        self.history = [
            .init(role: .system, content: .text(systemPrompt)),
            .init(role: .user, content: .text(initPrompt)),
        ]
        return try await getResponse()
    }
    
    public func getAnswer(for userInput: String) async throws -> [String]? {
        let answer = self.options.conversationPrompt.answer.replacingOccurrences(of: "{{.Answer}}", with: userInput)
        self.history.append(.init(role: .user, content: .text(answer)))
        guard let response = try await getResponse() else { return nil }
        return [ response ]
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
        return prompt.replacingOccurrences(of: "{{.Language}", with: self.options.learningLanguage.label)
                     .replacingOccurrences(of: "{{.Persona}}", with: self.persona)
                     .replacingOccurrences(of: "{{.Place}}", with: self.place)
                     .replacingOccurrences(of: "{{.Topic}}", with: self.topic)
    }
    
}
