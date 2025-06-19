import Foundation
import SwiftUI

struct EditOptionsView: View {
    
    @EnvironmentObject var options: Options
        
    var body: some View {
        VStack {
            NavigationLink(
                destination: PromptEditView(
                    prompt: options.conversationPrompt,
                    onSave: { newPrompt in
                        options.conversationPrompt = newPrompt
                    }
                )
            ) {
                Text("Edit Conversation Prompt")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            NavigationLink(
                destination: PromptEditView(
                    prompt: options.translationPrompt,
                    onSave: { newPrompt in
                        options.translationPrompt = newPrompt
                    }
                )
            ) {
                Text("Edit Translation Prompt")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            NavigationLink(
                destination: PromptEditView(
                    prompt: options.quizPrompt,
                    onSave: { newPrompt in
                        options.quizPrompt = newPrompt
                    }
                )
            ) {
                Text("Edit Quiz Prompt")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Edit Options")
        .padding()
    }
}

struct EditPromptsView_Previews: PreviewProvider {
    static var previews: some View {
        EditOptionsView().environmentObject(Options())
    }
}
