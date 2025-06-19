import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var options: Options
    
    var body: some View {
        NavigationView() {
            VStack {
                Text("Language Tutor")
                    .font(.largeTitle)
                
                Form {
                    Section() {
                        // Native Language Picker
                        Picker("Select your native language", selection: $options.nativeLanguage) {
                            ForEach(languages) { language in
                                Text(language.label).tag(language as LanguageOption)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.top, 5)
                        
                        // Learning Language Picker
                        Picker("Select the language you are learning", selection: $options.learningLanguage) {
                            ForEach(languages) { language in
                                Text(language.label).tag(language as LanguageOption)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.top, 5)
                        
                        // Proficiency Level TextField
                        VStack(alignment: .leading) {
                            Text("Proficiency Level")
                                .font(.headline)
                            TextField("Enter your proficiency level (e.g., Beginner, Intermediate, Advanced)", text: $options.level)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.top, 5)
                        }
                    }
                    
                    NavigationLink(
                        destination: MessagingView(
                            bot: TranslationBot(
                                type: .nativeToLearning,
                                options: options
                            ),
                            tools: Tools(options: options),
                            autoPlayEnabled: false,
                            tokenizeTextEnabled: false
                        )
                    ) {
                        Text("Translate to \(options.learningLanguage.label)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(
                        destination: MessagingView(
                            bot: TranslationBot(
                                type: .learningToNative,
                                options: options
                            ),
                            tools: Tools(options: options),
                            autoPlayEnabled: false,
                            tokenizeTextEnabled: false
                        )
                    ) {
                        Text("Translate from \(options.learningLanguage.label)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(
                        destination: MessagingView(
                            bot: PhraseBot(
                                options: options
                            ),
                            tools: Tools(options: options),
                            autoPlayEnabled: false,
                            tokenizeTextEnabled: false
                        )
                    ) {
                        Text("Phrase practice")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(
                        destination: MessagingView(
                            bot: QuizBot(
                                options: options
                            ),
                            tools: Tools(options: options),
                            autoPlayEnabled: false,
                            tokenizeTextEnabled: false
                        )
                    ) {
                        Text("Quiz")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(
                        destination: ConversationView()
                    ) {
                        Text("Start Conversation")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: EditOptionsView()) {
                        Text("Edit Options")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(Options())
    }
}
