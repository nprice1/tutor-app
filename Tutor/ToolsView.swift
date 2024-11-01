import SwiftUI
import AVFoundation
import SwiftOpenAI

struct ToolsView: View {
    private let text: String
    private let tools: Tools
    
    @State private var resultText: String
    
    init(text: String, options: Options) {
        self.text = text
        self.tools = Tools(options: options)
        self.resultText = ""
    }
    
    var body: some View {
        GeometryReader { geometry in
            
            VStack(spacing: 20) {
                ScrollView {
                    Text(text)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(.systemCyan))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                
                if !resultText.isEmpty {
                    ScrollView {
                        Text(resultText)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color(.green))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 15) {
                    Button(action: {
                        Task {
                            await translateText()
                        }
                    }) {
                        Text("Translate")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ModernButtonStyle())
                    
                    Button(action: {
                        Task {
                            await speakText()
                        }
                    }) {
                        Text("Speak")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(tools.isPlayingAudio())
                    .buttonStyle(ModernButtonStyle())
                    
                    Button(action: {
                        Task {
                            await writeInHiragana()
                        }
                    }) {
                        Text("To Hiragana")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ModernButtonStyle())
                }
            }
            .padding()
        }
        .navigationTitle("Tools")
    }
    
    private func translateText() async {
        DispatchQueue.main.async {
            resultText = "Translating..."
        }
        await getResult(toolFunction: {
            return try await tools.translate(text: text)
        })
    }
    
    private func writeInHiragana() async {
        DispatchQueue.main.async {
            resultText = "Converting..."
        }
        await getResult(toolFunction: {
            return try await tools.writeInHiragana(text: text)
        })
    }
    
    private func speakText() async {
        if (tools.isAudioLoaded()) {
            tools.replayAudio()
        } else {
            await tools.textToSpeech(text: text)
        }
    }
    
    private func getResult(toolFunction: @escaping () async throws -> String?) async {
        do {
            let response = try await toolFunction()
            if let response {
                DispatchQueue.main.async {
                    resultText = response
                }
            } else {
                DispatchQueue.main.async {
                    resultText = "Failed to get translated response"
                }
            }
        } catch APIError.responseUnsuccessful(let description, let statusCode) {
            DispatchQueue.main.async {
                resultText = "OpenAI Error: status=\(statusCode) description=\(description)"
            }
        } catch {
            DispatchQueue.main.async {
                resultText = "Unknown error: error=\(error)"
            }
        }
    }

}

struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ? Color.blue.opacity(0.7) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: configuration.isPressed ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1), radius: 5, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ToolsView_Previews: PreviewProvider {
    static var previews: some View {
        ToolsView(text: "Example text", options: Options())
    }
}
