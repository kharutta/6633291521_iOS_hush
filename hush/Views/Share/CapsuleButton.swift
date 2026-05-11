import SwiftUI

struct CapsuleButton: View {
    let title: String
    var isSelected: Bool = false

    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.mint : Color.white.opacity(0.1))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(20)
    }
}
