import SwiftUI

struct TestingScreenView: View {
    let frequency: Int
    let decibels: Float
    let isPlaying: Bool
    var onHear: () -> Void

    var body: some View {
        VStack(spacing: 50) {
            VStack(spacing: 20) {
                Text("\(frequency) Hz")
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Text("\(String(format: "%.2f", decibels)) dB")
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            ZStack {
                Circle()
                    .stroke(isPlaying ? Color.mint : Color.white.opacity(0.1), lineWidth: 4)
                    .scaleEffect(isPlaying ? 1.4 : 1.0)
                    .opacity(isPlaying ? 0 : 1)
                    .animation(isPlaying ? .easeOut(duration: 1.0).repeatForever(autoreverses: false) : .default, value: isPlaying)
                    .frame(width: 180, height: 180)

                Button(action: onHear) {
                    Text("I Hear It")
                        .font(.headline)
                        .foregroundColor(isPlaying ? .black : .mint)
                        .padding(50)
                        .background(isPlaying ? Color.mint : Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(!isPlaying)
            }
            Text("Listen carefully for the tone...")
                .foregroundColor(.gray)
        }
    }
}
