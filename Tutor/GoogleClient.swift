import GoogleAPIClientForREST_Texttospeech
import AVFoundation

class GoogleClient {
    
    private var apiKey = Bundle.main.infoDictionary?["GOOGLE_API_KEY"] as? String ?? ""
    private var ttsService = GTLRTexttospeechService()
    
    static let client = GoogleClient()
    
    private init() {
        ttsService.apiKey = apiKey
    }
    
    func translate(text: String, language: String) async throws -> String {
        // Set up the translation API endpoint
        let urlString = "https://translation.googleapis.com/language/translate/v2"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "TranslationAPI", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        // Prepare the request payload
        let params: [String: Any] = [
            "q": text,
            "target": language
        ]

        // Convert the params into JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            throw NSError(domain: "TranslationAPI", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize parameters"])
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(apiKey)", forHTTPHeaderField: "X-goog-api-key")  // Insert access token here
        request.httpBody = jsonData

        // Send the request
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            getTranslationResponse(request: request, completion: { (translation, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let translation = translation {
                    continuation.resume(returning: translation)
                } else {
                    continuation.resume(throwing: NSError(domain: "TranslationAPI", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No data or response received"]))
                }
            })
        }
    }
    
    func textToSpeech(text: String, language: String) async throws -> Data {
        // Set up the request object for Text-to-Speech
        let request = GTLRTexttospeech_VoiceSelectionParams()
        request.languageCode = language
        request.ssmlGender = "MALE"  // Other options: MALE, FEMALE
        
        let audioConfig = GTLRTexttospeech_AudioConfig()
        audioConfig.audioEncoding = "MP3"  // You can also use OGG_OPUS
        
        let input = GTLRTexttospeech_SynthesisInput()
        input.text = text
        
        let synthesizeRequest = GTLRTexttospeech_SynthesizeSpeechRequest()
        synthesizeRequest.input = input
        synthesizeRequest.voice = request
        synthesizeRequest.audioConfig = audioConfig
        
        // Create the query to request synthesis from Google Cloud
        let query = GTLRTexttospeechQuery_TextSynthesize.query(withObject: synthesizeRequest)
        
        // Execute the query
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            ttsService.executeQuery(query) { (ticket, response, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                
                // Extract the audio content from the response
                if let response = response as? GTLRTexttospeech_SynthesizeSpeechResponse, let audioContent = response.audioContent {
                    if let audioData = Data(base64Encoded: audioContent) {
                        continuation.resume(returning: audioData)
                    } else {
                        continuation.resume(throwing: NSError(domain: "TextToSpeechAPI", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to parse data"]))
                    }
                } else {
                    continuation.resume(throwing: NSError(domain: "TextToSpeechAPI", code: 1003, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                }
            }
        }
    }
    
    private func getTranslationResponse(request: URLRequest, completion: @escaping (String?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "TranslationAPI", code: 1003, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            // Parse the response
            do {
                print("\(String(data: data, encoding: .utf8)!)")
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let translations = jsonResponse["data"] as? [String: Any],
                   let translationArray = translations["translations"] as? [[String: Any]],
                   let translation = translationArray.first?["translatedText"] as? String {
                    completion(translation, nil)
                } else {
                    completion(nil, NSError(domain: "TranslationAPI", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Failed to parse translation response"]))
                }
            } catch {
                completion(nil, error)
            }
        }
    
        task.resume()
    }

}
