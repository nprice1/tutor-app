import SwiftUI

struct PromptEditView: View {
        
    @State private var answer: String = ""
    @State private var initialize: String = ""
    @State private var system: String = ""
    @State private var replacements: [String] = []
    
    private var prompt: Prompt
    private var onSave: (_ newPrompt: Prompt) -> Void
    
    init(prompt: Prompt, onSave: @escaping (_ newPrompt: Prompt) -> Void) {
        self.prompt = prompt
        self.onSave = onSave
    }
    
    var body: some View {
        VStack {
            Text("Replacements:")
                .font(.headline)
            List {
                ForEach(prompt.replacements, id: \.self) { replacement in
                    Text(replacement)
                }
            }
            
            Text("Answer:")
                .font(.headline)
            TextEditor(text: $answer)
                .border(Color.gray, width: 1)
                .padding(.bottom)

            Text("Initialize:")
                .font(.headline)
            TextEditor(text: $initialize)
                .border(Color.gray, width: 1)
                .padding(.bottom)

            Text("System:")
                .font(.headline)
            TextEditor(text: $system)
                .border(Color.gray, width: 1)
                .padding(.bottom)
            
            Button("Save") {
                onSave(Prompt(answer: self.answer, initialize: self.initialize, system: self.system, replacements: self.prompt.replacements))
            }
            .padding()
        }.onAppear() {
            self.answer = prompt.answer
            self.initialize = prompt.initialize ?? ""
            self.system = prompt.system
        }
        .padding()
        .navigationTitle("Edit Prompt")
    }
    
}

struct PromptEditView_Previews: PreviewProvider {
    static var previews: some View {
        PromptEditView(prompt: Options().translationPrompt, onSave: { _ in })
    }
}
