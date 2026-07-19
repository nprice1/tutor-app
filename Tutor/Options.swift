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

struct ConversationTopicResponse: Codable {
    let setup: String
    let opening: String
    let persona: String
}

struct ConversationAnalysisResponse: Codable {
    let classification: String
    let feedback: String
    let correction: String
}

struct ExercisePrompt: Codable {
    let exercise: String?
    let correction: String?
    let explanation: String?
}

struct ListeningPracticeResponse: Codable {
    let conversation: String
    let translation: String
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
    LanguageOption(label: "Russian", value: "ru"),
    LanguageOption(label: "Icelandic", value: "is")
]

class Options: ObservableObject {

    @Published var learningLanguage: LanguageOption = languages[1]
    @Published var nativeLanguage: LanguageOption = languages[0]
    @Published var level: String = "intermediate"
    @Published var conversationPrompt: Prompt = Prompt(
        answer: """
        {{.Answer}}
            
        IMPORTANT: When you respond, please respond like a person: short and concise responses that maintain the flow of the conversation.
        DO NOT ANSWER LIKE A ROBOT, this is meant for real conversation practice. Focus on maintaining human like conversations.
        """,
        initialize: """
        Generate ONE new conversation topic.

        Rules:
        - Everyday real-life situation
        - Not about language learning
        - Not a classroom or study context
        - Not dramatic or fantasy
        - Something two people might casually talk about
        - Short and simple setup

        Return JSON with:
        {
          "setup": "1–2 sentences explaining the situation in English",
          "opening": "first line spoken in natural {{.LearningLanguage}}",
          "persona": "who the tutor is (friend, coworker, clerk, etc.)"
        }
        
        Example:
        {
          "setup": "You're having lunch with a coworker. They recently went on a short trip.",
          "opening": "この前の週末、ちょっと京都に行ってきたんだけどさ。",
          "persona": "coworker"
        }

        """,
        system: """
        You generate realistic, everyday conversation scenarios
        for {{.LearningLanguage}} listening practice.

        You are NOT a teacher.
        You do NOT explain language.
        You speak and think like a native {{.LearningLanguage}} person.

        Conversations must feel natural, casual, and human.
        They must NOT feel like an AI or a lesson.

        You always follow the output format exactly.
        """,
        replacements: [
            "{{.LearningLanguage}}",
            "{{.NativeLanguage}}",
            "{{.Answer}}",
            "{{.Setup}}",
            "{{.Persona}}",
            "{{.Answer}}"
        ]
    )
    @Published var conversationAnalysisPrompt: String = """
        Conversation context:
        - Situation: {{.Setup}}
        - Persona: {{.Persona}}
        - Last tutor message ({{.LearningLanguage}}):
        "{{.LastTutorMessage}}"

        User replied in {{.LearningLanguage}}:
        "{{.Answer}}"

        Classify the user's reply into ONE category:
        - NATURAL: sounds fine
        - UNDERSTANDABLE: slightly off but usable
        - CONTEXT_ERROR: grammatically okay but meaning doesn't fit
        - GRAMMAR_ERROR: meaning clear but grammar is wrong
        - NON_SENSE: does not make sense in this conversation

        Rules:
        - Be lenient unless meaning is wrong
        - Do NOT teach in {{.LearningLanguage}}
        - {{.NativeLanguage}} is used ONLY for explanations
        - {{.LearningLanguage}} replies must sound natural, not like a textbook

        Return JSON:
        {
          "classification": "NATURAL | UNDERSTANDABLE | CONTEXT_ERROR | GRAMMAR_ERROR | NON_SENSE",
          "feedback": "empty if NATURAL or UNDERSTANDABLE",
          "correction": "only if correction is needed",
        }

        Examples: 
        
        Natural:
        {
          "classification": "NATURAL",
          "feedback": "",
          "correction": ""
        }

        Grammar error:
        {
          "classification": "GRAMMAR_ERROR",
          "feedback": "You're very close. When talking about an experience, use 「行くのは」 instead of 「行くは」.",
          "correction": "京都に行くのは楽しかった。"
        }

        Nonsense:
        {
          "classification": "NON_SENSE",
          "feedback": "That response doesn't really fit the conversation. Try reacting to the trip or asking a question about it.",
          "correction": ""
        }
    """
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
    @Published var listeningPracticePrompt: Prompt = Prompt(
        answer: """
        Continue the conversation, or start a new one if the conversation is over. Please provide the next part in the following JSON format:
        {
            \"conversation\": \"Current speakers part of the conversation in {{.LearningLanguage}} goes here\"
            \"translation\": \"Translation of current speakers part of the conversation in {{.NativeLanguage}} goes here\"
        }
        """,
        initialize: """
        Come up with an example conversation to help me practice listenting to {{.LearningLanguage}}. Avoid telling childrens stories or myths, and
        instead focus on example conversations one might here when travelling to a country where they speak {{.LearningLanguage}}.
        I am at an {{.Level}} level for {{.LearningLanguage}},
        so the conversation should focus on words/grammar that are suitable for my current proficiency level.
        
        You do not need to provide the full conversation, instead provide the conversation in chunks to make it sound more natural and have it be
        easier to understand. Keep the conversation concise to closely resemble an actual conversation.
        
        The conversation should be between multiple simulated people. You should return responses for one speaker at a time. So for a 
        conversation between Speaker A and Speaker B, the first response would only be for Speaker A.
        
        Return your response in the following JSON format:
        
        {
            \"conversation\": \"Current speakers part of the conversation in {{.LearningLanguage}} goes here\"
            \"translation\": \"Translation of current speakers part of the conversation in {{.NativeLanguage}} goes here\"
        }
        """,
        system: """
        You are a {{.LearningLanguage}} tutor. Your goal is to assist me in my comprehensive understanding of {{.LearningLanguage}}. You should
        keep all your answers as concise as possible to simulate realistic conversations.
        """,
        replacements: [
            "{{.NativeLanguage}}",
            "{{.LearningLanguage}}",
            "{{.Level}}",
        ]
    )
    @Published var hiraganaPrompt: String = "Please write {{.Text}} using only hiragana."
    @Published var translatePrompt: String = "Please translate {{.Text}} into {{.NativeLanguage}}"
    @Published var tokenizePrompt: String = """
    Take the following {{.LearningLanguage}} sentence and tokenize it into each word. Please keep any punctuation that is attached
    to any words, do not create separate entries for them. Please dont create separate entries for grammatical structures
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
