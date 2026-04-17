import SwiftUI

struct CumulativeStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
