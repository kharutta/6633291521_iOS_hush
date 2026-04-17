import SwiftUI

struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = .white

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).bold().foregroundColor(valueColor)
        }
        .padding()
    }
}
