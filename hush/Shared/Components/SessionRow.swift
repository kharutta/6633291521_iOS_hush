import SwiftUI

struct SessionRow: View {
    let title: String
    let sub: String
    let percent: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle().fill(Color.teal).frame(width: 8, height: 8)
                    Text(title).font(.body).bold()
                }
                Text(sub).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Text(percent).font(.body).bold()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
