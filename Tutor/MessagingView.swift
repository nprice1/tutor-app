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
    let tokenizedWords: [TokenizedWord]?
    
    init(text: String, type: ChatMessageType) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.tokenizedWords = nil
    }
    
    init(text: String, type: ChatMessageType, tokenizedWords: [TokenizedWord]) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.tokenizedWords = tokenizedWords
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
    @StateObject private var audioSpeaker = AudioSpeaker()
    
    private let chatBot: ChatBot
    private let tools: Tools
    private let autoPlayEnabled: Bool
    private let tokenizeTextEnabled: Bool
    
    init(bot: ChatBot, tools: Tools, autoPlayEnabled: Bool, tokenizeTextEnabled: Bool) {
        self.chatBot = bot
        self.tools = tools
        self.autoPlayEnabled = autoPlayEnabled
        self.tokenizeTextEnabled = tokenizeTextEnabled
    }
    
    var body: some View {
        VStack {
            chatScrollView
            inputBar
        }
        .task {
            if chatHistory.isEmpty {
                await fetchInitialMessage()
            }
        }
        .onChange(of: audioTranscriber.transcribedAudio) {
            self.messageText = audioTranscriber.transcribedAudio
        }
    }
    
    private var chatScrollView: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(chatHistory, id: \.id) { message in
                        chatBubble(for: message)
                            .id(message.id)
                    }

                    if isLoadingMessage {
                        MessageView(
                            text: "...",
                            tokenizedWords: nil,
                            isCurrentUser: false
                        )
                    }
                }
            }
            .onChange(of: chatHistory.count) {
                value.scrollTo(chatHistory.last?.id, anchor: .bottom)
                if autoPlayEnabled {
                    Task { await speakLastMessage() }
                }
            }
            .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func chatBubble(for message: ChatMessage) -> some View {
        if message.type == .system {
            SpeechBubbleTextView(
                text: message.text,
                words: message.tokenizedWords ?? []
            )
            .padding(.vertical, 4)
            .padding(.horizontal)
        } else {
            MessageView(
                text: message.text,
                tokenizedWords: nil,
                isCurrentUser: message.type == .user
            )
        }
    }

    private var inputBar: some View {
        VStack {
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

            HStack {
                sendButton
                recordButton
                toolsButton
                stopButton
            }
            .padding()
        }
    }

    private var sendButton: some View {
        Button(action: {
            Task { await sendMessage() }
        }) {
            Image(systemName: "paperplane.fill")
                .font(.title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
        .padding(.leading, 8)
    }

    private var recordButton: some View {
        Button(action: {
            Task {
                do {
                    try await toggleRecording()
                } catch {
                    print("Recording error: \(error)")
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
    }

    private var toolsButton: some View {
        Group {
            if toolsEnabled {
                NavigationLink(
                    destination: ToolsView(text: highlightedText ?? "", options: options)
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
    }

    private var stopButton: some View {
        Group {
            if audioSpeaker.isPlaying {
                Button(action: {
                    stopSpeaking()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
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
                var chatMessages: [ChatMessage] = []
                for message in messages {
                    let tokenizedWords = tokenizeTextEnabled ? try await self.tools.getTokenizedResponse(response: message) : nil
                    let chatMessage = ChatMessage(text: message, type: .system, tokenizedWords: tokenizedWords ?? [])
                    chatMessages.append(chatMessage)
                }
                return chatMessages
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
    
    private func speakLastMessage() async {
        if let lastMessage = chatHistory.last {
            if lastMessage.type == .system {
                Task {
                    await audioSpeaker.textToSpeech(options: self.options, text: lastMessage.text)
                }
            }
        }
    }
    
    private func stopSpeaking() {
        self.audioSpeaker.stopAudio()
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
            ),
            autoPlayEnabled: true,
            tokenizeTextEnabled: true
        ).environmentObject(Options())
    }
    
}
