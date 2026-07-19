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
    let tokenizedWords: [TokenizedWord]
    let language: String
    
    init(text: String, language: String, type: ChatMessageType) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.tokenizedWords = []
        self.language = language
    }
    
    init(text: String, language: String, type: ChatMessageType, tokenizedWords: [TokenizedWord]) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.tokenizedWords = tokenizedWords
        self.language = language
    }
}

struct MessagingView: View {
    @EnvironmentObject var options: Options
    
    @State private var messageText: String = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var isLoadingMessage = true
    @State private var previousChatSize = 0
    @State private var finishedPlayingMessages = false;
    @State private var autoTranscribe = false;
    @StateObject private var audioTranscriber = AudioTranscriber()
    @StateObject private var audioSpeaker = AudioSpeaker()
    
    private let chatBot: ChatBot
    private let tools: Tools
    private let autoPlayEnabled: Bool
    private let tokenizeTextEnabled: Bool
    private var autoContinueEnabled: Bool
    
    init(bot: ChatBot,
         tools: Tools,
         autoPlayEnabled: Bool,
         tokenizeTextEnabled: Bool,
         autoContinueEnabled: Bool,
         autoTranscribe: Bool) {
        self.chatBot = bot
        self.tools = tools
        self.autoPlayEnabled = autoPlayEnabled
        self.tokenizeTextEnabled = tokenizeTextEnabled
        self.autoContinueEnabled = autoContinueEnabled
        self.autoTranscribe = autoTranscribe
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
                            tokenizedWords: [],
                            isCurrentUser: false
                        )
                    }
                }
            }
            .onChange(of: chatHistory.count) {
                value.scrollTo(chatHistory.last?.id, anchor: .bottom)
                let newMessages = Array(chatHistory[previousChatSize..<chatHistory.count])
                previousChatSize = chatHistory.count
                        
                if (autoPlayEnabled && chatHistory.last?.type == .system) {
                    finishedPlayingMessages = false
                    Task {
                        for message in newMessages {
                            while (audioSpeaker.isPlaying) {
                                try? await Task.sleep(nanoseconds: 5_000_000_000)
                            }
                            if message.type == .system {
                                await audioSpeaker.textToSpeech(language: message.language, text: message.text)
                            }
                        }
                        while (audioSpeaker.isPlaying) {
                            try? await Task.sleep(nanoseconds: 5_000_000_000)
                        }
                        finishedPlayingMessages = true
                    }
                }
            }
            .onChange(of: finishedPlayingMessages) {
                if (finishedPlayingMessages && autoContinueEnabled) {
                    Task {
                        await sendMessage()
                    }
                }
                if (finishedPlayingMessages && autoTranscribe) {
                    Task {
                        do {
                            try await toggleRecording()
                        } catch {
                            print("Recording error: \(error)")
                        }
                    }
                }
            }
            .onChange(of: audioTranscriber.isTranscribing) {
                if (autoTranscribe &&
                    !audioTranscriber.isTranscribing &&
                    !audioTranscriber.isRecording &&
                    finishedPlayingMessages) {
                    Task {
                        await sendMessage()
                    }
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }

    @ViewBuilder
    private func chatBubble(for message: ChatMessage) -> some View {
        if message.type == .system {
            MessageView(
                text: message.text,
                tokenizedWords: message.tokenizedWords,
                isCurrentUser: false,
                onPlayAudio: {
                    Task {
                        await audioSpeaker.textToSpeech(language: message.language, text: message.text)
                    }
                }
            )
        } else {
            MessageView(
                text: message.text,
                tokenizedWords: message.tokenizedWords,
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
                stopButton
                toggleAutoTranscribeButton
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
        .padding(.leading, 8)
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
                .padding(.leading, 8)
            }
        }
    }

    private var toggleAutoTranscribeButton: some View {
        Button(action: {
            toggleAutoTranscribe()
        }) {
            Image(systemName: autoTranscribe ? "message.badge.waveform.fill" : "message.badge.waveform")
                .font(.title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
        .padding(.leading, 8)
    }
    
    private func fetchInitialMessage() async {
        DispatchQueue.main.async {
            isLoadingMessage = true
        }
        let messages = await getSystemResponse(fetchMessagesFunction: {
            let prompt = try await chatBot.getInitialPrompt()
            if let prompt {
                return prompt
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
            chatHistory.append(ChatMessage(text: messageText, language: chatBot.getResponseLanguage(), type: ChatMessageType.user))
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
    
    private func getSystemResponse(fetchMessagesFunction: @escaping () async throws -> [ChatBotMessage]?) async -> [ChatMessage] {
        do {
            let messages = try await fetchMessagesFunction()
            if let messages {
                var chatMessages: [ChatMessage] = []
                for message in messages {
                    let shouldTokenize = tokenizeTextEnabled && message.language == options.learningLanguage.value
                    let tokenizedWords = shouldTokenize ? try await self.tools.getTokenizedResponse(response: message.message) : nil
                    let chatMessage = ChatMessage(text: message.message, language: message.language, type: .system, tokenizedWords: tokenizedWords ?? [])
                    chatMessages.append(chatMessage)
                }
                return chatMessages
            } else {
                return [ChatMessage(text: "Failed to get response", language: "en", type: ChatMessageType.error)]
            }
        } catch APIError.responseUnsuccessful(let description, let statusCode) {
            return [ChatMessage(text: "OpenAI Error: status=\(statusCode) description=\(description)", language: "en", type: ChatMessageType.error)]
        } catch {
            return [ChatMessage(text: "Unknown error: error=\(error)", language: "en", type: ChatMessageType.error)]
        }
    }
               
    private func toggleRecording() async throws {
        if (audioTranscriber.isRecording) {
            audioTranscriber.stopRecording()
            await audioTranscriber.transcribeAudio(language: chatBot.getResponseLanguage())
        } else {
            await audioTranscriber.startRecording(language: chatBot.getResponseLanguage())
        }
    }
    
    private func stopSpeaking() {
        self.audioSpeaker.stopAudio()
    }
    
    private func toggleAutoTranscribe() {
        self.autoTranscribe = !autoTranscribe
    }

}

struct MessagingView_Previews: PreviewProvider {
    
    static var previews: some View {
        MessagingView(
            bot: ListeningPracticeBot(
                options: Options()
            ),
            tools: Tools(
                options: Options()
            ),
            autoPlayEnabled: true,
            tokenizeTextEnabled: false,
            autoContinueEnabled: true,
            autoTranscribe: false
        ).environmentObject(Options())
    }
    
}
