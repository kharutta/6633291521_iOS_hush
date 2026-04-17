import SwiftUI

struct StartScreenView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "ear.and.waveform")
                .font(.system(size: 80))
                .foregroundColor(.mint)
            Text("Hearing Test")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            Text("We will play tones at different frequencies. Tap the button as soon as you hear the faint sound.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            Button(action: onStart) {
                Text("Start Test")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mint)
                    .foregroundColor(.black)
                    .cornerRadius(15)
            }.padding(.horizontal, 40)
        }
    }
}
