import SwiftUI

struct StartScreenView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "ear.and.waveform")
                .font(.system(size: 70))
                .foregroundColor(.mint)
            Text("Hearing Test")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(
                    icon: "waveform",
                    title: "Frequency (Hz)",
                    desc: "How high or low a tone sounds. We test from low to high pitch."
                )
                InstructionRow(
                    icon: "speaker.wave.1",
                    title: "Volume (dB HL)",
                    desc: "How loud the tone is. We start very quiet and slowly get louder."
                )
                InstructionRow(
                    icon: "hand.tap",
                    title: "Tap when you hear it",
                    desc: "As soon as you notice a faint tone, tap \"I Hear It\" immediately."
                )
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            VStack(spacing: 16) {
                Text("Before You Start")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.mint)

                VStack(alignment: .leading, spacing: 16) {
                    InstructionRow(
                        icon: "headphones",
                        title: "Wear your headphones",
                        desc: ""
                    )
                    InstructionRow(
                        icon: "speaker.wave.2",
                        title: "Set your volume to maximum",
                        desc: ""
                    )
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            
            Button(action: onStart) {
                Text("Start Test")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mint)
                    .foregroundColor(.black)
                    .cornerRadius(15)
            }.padding(.horizontal)
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.mint)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .bold()
                    .foregroundColor(.white)
                if desc != "" {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }.frame(width: 320)
    }
}

