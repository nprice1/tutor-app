//
//  ChatBot.swift
//  Tutor
//
//  Created by Nolan Price on 9/13/24.
//

import Foundation

struct ChatBotMessage {
    let message: String
    let language: String
}

protocol ChatBot {
    
    func getInitialPrompt() async throws -> [ChatBotMessage]?
    func getAnswer(for userInput: String) async throws -> [ChatBotMessage]?
    func getResponseLanguage() -> String
    
}
