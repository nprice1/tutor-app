import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var options: Options
    
    @State private var persona: String = ""
    @State private var place: String = ""
    @State private var topic: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Start a Conversation")
                .font(.largeTitle)
                .padding()

            TextField("Enter Persona", text: $persona)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Enter Place", text: $place)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Enter Topic", text: $topic)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            NavigationLink(
                destination: 
                    MessagingView(
                        bot: ConversationBot(
                            options: options,
                            persona: persona,
                            place: place,
                            topic: topic
                        ),
                        tools: Tools(options: options)
                    )
            ) {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Start a Conversation")
        .padding()
    }
}


struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationView().environmentObject(Options())
    }
}
