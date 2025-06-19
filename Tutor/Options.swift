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

struct ExercisePrompt: Codable {
    let exercise: String?
    let correction: String?
    let explanation: String?
}

struct TokenizedWordsResponse: Codable {
    let words: [TokenizedWord]
}

struct TokenizedWord: Codable, Identifiable {
    let id = UUID()
    let word: String
    let reading: String
    let definition: String
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
    @Published var quizPrompt: Prompt = Prompt(
        answer: """
        {{.Answer}}
        """,
        initialize: """
        Create a quiz to help me practice speaking {{.LearningLanguage}}. The questions and all correctsions should be provided in {{.NativeLanguage}}.
        I am at an {{.Level}} level for {{.LearningLanguage}},
        so the quiz should focus on short-answer questions that are suitable for my current proficiency level that cover vocabulary and grammar. The quiz
        should focus on testing my knowledge of vocabulary and grammar for the language, so please do not ask personal questions about my likes or
        dislikes.
        Please ensure that the questions are designed
        to be answered in {{.LearningLanguage}} only. Do not ask questions that require switching to {{.NativeLanguage}} such as asking for translations
        into {{.NativeLanguage}} or definitions of words in {{.NativeLanguage}}.
        
        - Ask one question at a time, and allow me to answer in {{.LearningLanguage}}.
        - Each question should be asked in {{.NativeLanguage}}.
        - All corrections and explanations should be given in {{.NativeLanguage}}.
        - Focus on vocabulary and grammar related questions that are suitable to my proficiency level. Do not ask personal questions like me likes or
        dislikes.
        - After I answer, provide the correct answer and give any necessary corrections or feedback.
        - Ensure that the quiz questions are logically consistent within {{.LearningLanguage}}
          (i.e., no asking for the meaning of a word in {{.NativeLanguage}} and then later asking for that word in {{.LearningLanguage}}).
        - Gradually increase the difficulty of questions, starting with {{.Level}} questions.
        - Provide explanations and examples when necessary to clarify mistakes.
        """,
        system: """
        You are a {{.LearningLanguage}} tutor. Your goal is to assist me in my comprehensive understanding of {{.LearningLanguage}}
        """,
        replacements: [
            "{{.NativeLanguage}}",
            "{{.LearningLanguage}}",
            "{{.Question}}",
            "{{.Level}}",
            "{{.Answer}}"
        ]
    )
    @Published var hiraganaPrompt: String = "Please write {{.Text}} using only hiragana."
    @Published var translatePrompt: String = "Please translate {{.Text}} into {{.NativeLanguage}}"
    @Published var tokenizePrompt: String = """
    Take the following {{.LearningLanguage}} sentence and tokenize it into each word. Please keep any punctuation that is attached
    to any words, do not create separate entries for them. Please dont create separate entries for common words or grammatical structures
    such as sentence particles, instead keep them attached to the words they modify. For each word, create a JSON object matching this
    schema:
    ```
    {
        \"word\": \"<The word in {{.LearningLanguage}} goes here>\",
        \"reading\": \"<The word written in hiragana goes here>\",
        \"definition\": \"<The {{.NativeLanguage}} definition of the word goes here>\"
    }
    ```
    Finally, return all of the words as a JSON array following this schema:
    ```
    {
      \"words\": [
         <All of the word JSON objects go here>
      ]
    }
    ```

    Sentence:
    "{{.Input}}"    
    """

}
