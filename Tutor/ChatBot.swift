//
//  ChatBot.swift
//  Tutor
//
//  Created by Nolan Price on 9/13/24.
//

import Foundation

protocol ChatBot {
    
    func getInitialPrompt() async throws -> String?
    func getAnswer(for userInput: String) async throws -> [String]?
    func getResponseLanguage() -> String
    
}
