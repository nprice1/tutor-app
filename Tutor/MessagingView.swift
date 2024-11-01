import SwiftUI
import AVFoundation
import SwiftOpenAI
import Foundation

enum ChatMessageType {
    case system
    case user
    case error
}

struct ChatMessage {
    let id: UUID
    let text: String
    let type: ChatMessageType
    
    init(text: String, type: ChatMessageType) {
        self.id = UUID()
        self.text = text
        self.type = type
    }
}

struct MessagingView: View {
    @EnvironmentObject var options: Options
    
    @State private var messageText: String = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var highlightedText: String? = nil
    @State private var toolsEnabled = false
    @State private var isLoadingMessage = true
    @StateObject private var audioTranscriber = AudioTranscriber()
    
    private let chatBot: ChatBot
    private let tools: Tools
    
    init(bot: ChatBot, tools: Tools) {
        self.chatBot = bot
        self.tools = tools
    }
    
    var body: some View {
        VStack {
            // Display chat history and initial message
            ScrollViewReader { value in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(chatHistory, id: \.id) { message in
                            HStack {
                                MessageView(
                                    text: message.text,
                                    isCurrentUser: message.type == .user,
                                    onTextSelected: { selectedText in
                                        DispatchQueue.main.async {
                                            self.highlightedText = selectedText
                                            self.toolsEnabled = !selectedText.isEmpty
                                        }
                                    },
                                    onTripleTap: { _ in
                                        DispatchQueue.main.async {
                                            self.highlightedText = message.text
                                            self.toolsEnabled = true
                                        }
                                        Task {
                                            do {
                                                await self.tools.textToSpeech(text: message.text)
                                            }
                                        }
                                    }
                                )
                                .id(message.id)
                            }
                        }
                        if (isLoadingMessage) {
                            MessageView(
                                text: "...",
                                isCurrentUser: false,
                                onTextSelected: { _ in },
                                onTripleTap: { _ in }
                            )
                        }
                    }
                }
                .onChange(of: chatHistory.count) {
                    value.scrollTo(chatHistory.last?.id, anchor: .bottom)
                }
                .textSelection(.enabled)
            }
            
            // Input TextField
            TextField("Type a message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(3)
                .background(Color.white)
                .cornerRadius(10)
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            
            // Buttons: Record and Tools
            HStack {
                // Send Button
                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(.leading, 8)
                
                // Record Button
                Button(action: {
                    Task {
                        do {
                            try await toggleRecording()
                        } catch {
                            print("Failed to send message: \(error)")
                        }
                    }
                }) {
                    Image(systemName: audioTranscriber.isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title)
                        .padding()
                        .background(audioTranscriber.isTranscribing ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .disabled(audioTranscriber.isTranscribing)
                
                // Tools Button
                if (toolsEnabled) {
                    NavigationLink(
                        destination: ToolsView(
                            text: highlightedText ?? "",
                            options: options
                        )
                    ) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
        }
        .task{
            if (chatHistory.isEmpty) {
                await fetchInitialMessage()
            }
        }
        .onChange(of: audioTranscriber.transcribedAudio) {
            DispatchQueue.main.async {
                self.messageText = audioTranscriber.transcribedAudio
            }
        }
    }
    
    private func fetchInitialMessage() async {
        DispatchQueue.main.async {
            isLoadingMessage = true
        }
        let messages = await getSystemResponse(fetchMessagesFunction: {
            let prompt = try await chatBot.getInitialPrompt()
            if let prompt {
                return [prompt]
            } else {
                return []
            }
        })
        DispatchQueue.main.async {
            chatHistory += messages
            isLoadingMessage = false
        }
    }
    
    private func sendMessage() async {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        DispatchQueue.main.async {
            chatHistory.append(ChatMessage(text: messageText, type: ChatMessageType.user))
            isLoadingMessage = true
            messageText = ""
        }
        let messages = await getSystemResponse(fetchMessagesFunction: {
            try await chatBot.getAnswer(for: messageText)
        })
        DispatchQueue.main.async {
            chatHistory += messages
            isLoadingMessage = false
        }
    }
    
    private func getSystemResponse(fetchMessagesFunction: @escaping () async throws -> [String]?) async -> [ChatMessage] {
        do {
            let messages = try await fetchMessagesFunction()
            if let messages {
                return messages.map {
                    message in ChatMessage(text: message, type: ChatMessageType.system)
                }
            } else {
                return [ChatMessage(text: "Failed to get response", type: ChatMessageType.error)]
            }
        } catch APIError.responseUnsuccessful(let description, let statusCode) {
            return [ChatMessage(text: "OpenAI Error: status=\(statusCode) description=\(description)", type: ChatMessageType.error)]
        } catch {
            return [ChatMessage(text: "Unknown error: error=\(error)", type: ChatMessageType.error)]
        }
    }
    
    private func toggleRecording() async throws {
        if (audioTranscriber.isRecording) {
            audioTranscriber.stopRecording()
            await audioTranscriber.transcribeAudio(language: chatBot.getResponseLanguage())
        } else {
            await audioTranscriber.startRecording()
        }
    }

}

struct MessagingView_Previews: PreviewProvider {
    
    static var previews: some View {
        MessagingView(
            bot: TestBot(
                options: Options()
            ),
            tools: Tools(
                options: Options()
            )
        ).environmentObject(Options())
    }
    
}
