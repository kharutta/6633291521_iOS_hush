import SwiftUI

struct InputField: View {
    var label: String
    var placeholder: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(label).foregroundColor(.gray)
            TextField(placeholder, text: .constant(""))
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
        }
    }
}
