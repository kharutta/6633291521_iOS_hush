import SwiftUI

struct StatBox: View {
    var label: String
    var value: String
    var valueColor: Color = .white

    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
