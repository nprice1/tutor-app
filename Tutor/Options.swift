import Foundation
import SwiftUI

enum ExerciseType {
    case translationFrom
    case translationTo
    case conversation
}

struct LanguageOption: Identifiable, Hashable {
    let id = UUID() // Unique identifier for each option
    let label: String
    let value: String
}

struct Prompt {
    let answer: String
    let initialize: String?
    let system: String
    let replacements: [String]
}

let languages = [
    LanguageOption(label: "English", value: "en"),
    LanguageOption(label: "Japanese", value: "ja"),
    LanguageOption(label: "Spanish", value: "es"),
    LanguageOption(label: "French", value: "fr"),
    LanguageOption(label: "German", value: "de"),
    LanguageOption(label: "Chinese", value: "zh"),
    LanguageOption(label: "Korean", value: "ko"),
    LanguageOption(label: "Russian", value: "ru")
]

class Options: ObservableObject {

    @Published var learningLanguage: LanguageOption = languages[1]
    @Published var nativeLanguage: LanguageOption = languages[0]
    @Published var level: String = "intermediate"
    @Published var conversationPrompt: Prompt = Prompt(
        answer: "{{.Answer}}",
        initialize: "Please begin the conversation.",
        system: """
        You are a native {{.Language}} speaker. Your persona is {{.Persona}} and you are currently at {{.Place}}. You are engaging me
        in a conversation about {{.Topic}}. I am new to {{.Language}}, so if I make any mistakes you should correct them
        before continuing the conversation.
        """,
        replacements: [
            "{{.Language}}",
            "{{.Persona}}",
            "{{.Place}}",
            "{{.Topic}}",
            "{{.Answer}}"
        ]
    )
    @Published var translationPrompt: Prompt = Prompt(
        answer: """
        You asked me this: {{.Exercise}}
        I answered with this: {{.Answer}}

        Is my answer correct? Please provide your response in the following JSON format:
        {
            \"correction\": \"<Provide the correct answer to the question here>\",
            \"explanation\": "<Provide a detailed explanation why my answer was correct or incorrect, and explain why your correction is correct here>"
        }
        """,
        initialize: """
        Provide a single translation exercise from {{.FromLanguage}} to {{.ToLanguage}}. Focus on common phrases or concepts that are commonly said
        in {{.FromLanguage}}. My current level in {{.ToLanguage}} is {{.Level}}, so please focus on translation exercises for that level. Please do
        not repeat any translation exercises. Please provide your answers in the following JSON format:
        {
            \"exercise\": \"<Translation exercise goes here>\"
        }
        """,
        system: """
        You are a {{.FromLanguage}} language teacher and I am your student. I am at a {{.Level}} level for {{.FromLanguage}}.
        Your task is to assist me understanding all aspects of {{.FromLanguage}}, and you should correct me whenever I make a mistake
        in {{.FromLanguage}}. When providing corrections, you should also explain your reasoning as to why my answer is correct or
        incorrect.
        """,
        replacements: [
            "{{.FromLanguage}}",
            "{{.ToLanguage}}",
            "{{.Exercise}}",
            "{{.Level}}",
            "{{.Answer}}"
        ]
    )
    @Published var phraseCorrectionPrompt: Prompt = Prompt(
        answer: """
        {{.Answer}}
        """,
        initialize: nil,
        system: """
        I am going to provide you with phrases in {{.LearningLanguage}}, and your job
        will be to do the following:
        1. Translate the phrase into {{.NativeLanguage}}.
        2. Provide any corrections if the phrase I gave is not gramatically accurate.
        3. Provide the grammatically accurate way to say the phrase I provided in {{.LearningLanguage}}.
        """,
        replacements: [
            "{{.LearningLanguage}}",
            "{{.NativeLanguage}}",
            "{{.Level}}",
            "{{.Answer}}"
        ]
    )
    @Published var hiraganaPrompt: String = "Please write {{.Text}} using only hiragana."
    @Published var translatePrompt: String = "Please translate {{.Text}} into {{.Language}}"

}
