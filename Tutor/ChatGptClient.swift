import Foundation
import SwiftOpenAI

private let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String ?? ""
private let model = Bundle.main.infoDictionary?["MODEL"] as? String ?? ""
private let temp = Bundle.main.infoDictionary?["TEMP"] as? Double ?? 1.0

private let service = OpenAIServiceFactory.service(apiKey: apiKey)

struct SpeechToTextResponse: Codable {
    let text: String?
}

struct ResponseType: Codable {
    let type: String
}

let debugMode = false

class ChatGptClient {
    
    static let client = ChatGptClient()
    
    private init() {
    }
    
    public func speechToText(fileUrl: URL, language: String) async throws -> String? {
        if (debugMode) {
            sleep(1)
            return "Example transcription"
        }
        let data = try! Data(contentsOf: fileUrl)
        let parameters = AudioTranscriptionParameters(fileName: "recording.m4a",
                                                      file: data,
                                                      language: language) // **Important**: in the file name always provide the file extension.
        let audioObject = try await service.createTranscription(parameters: parameters)
        return audioObject.text
    }
    
    public func textToSpeech(text: String) async throws -> Data {
        let parameters = AudioSpeechParameters(model: .tts1, input: text, voice: .onyx)
        let response = try await service.createSpeech(parameters: parameters)
        return response.output
    }
    
    public func getRawResponse(messages: [ChatCompletionParameters.Message], responseFormat: ResponseFormat) async throws -> String {
        if (debugMode) {
            sleep(1)
            return "Example raw response"
        }
        let parameters = ChatCompletionParameters(messages: messages,
                                                  model: .gpt4o,
                                                  responseFormat: responseFormat,
                                                  temperature: temp)
        let choices = try await service.startChat(parameters: parameters).choices
        return choices.first?.message.content ?? ""
    }
}
