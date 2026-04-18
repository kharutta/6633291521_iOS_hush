import SwiftUI

struct ResultSummaryView: View {
    let results: [Int: Float]
    let frequencies: [Int]
    var onReset: () -> Void

    private var averageDB: Float {
        let coreFreqs = [500, 1000, 2000, 4000]
        let sum = coreFreqs.reduce(0) { $0 + (results[$1] ?? 0) }
        return (sum / Float(coreFreqs.count)) * 100
    }

    private func interpretPTA(_ avg: Float) -> (status: String, info: String, color: Color) {
        switch avg {
        case ..<16:
            return ("Excellent (Normal)", "You can hear whispers and rustling leaves clearly.", .mint)
        case 16..<26:
            return ("Slightly Impaired", "You may have slight difficulty in very noisy environments.", .green)
        case 26..<41:
            return ("Mild Loss", "Quiet speech or distant sounds may be hard to hear.", .orange)
        case 41..<56:
            return ("Moderate Loss", "Normal conversation is difficult. people may need to speak louder.", .red)
        case 56..<71:
            return ("Moderately-Severe Loss", "Challenges with most everyday speech.", .red)
        case 71..<91:
            return ("Severe Loss", "Only very loud sounds are audible.", .purple)
        default:
            return ("Profound Loss", "Minimal or no usable hearing.", .purple)
        }
    }

    var body: some View {
        let interpretation = interpretPTA(averageDB)

        ScrollView {
            VStack(spacing: 25) {
                Text("Test Results")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                VStack(spacing: 15) {
                    Text("Pure Tone Average (PTA)")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("\(String(format: "%.1f", averageDB)) dB HL")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(interpretation.color)

                    Divider().background(Color.white.opacity(0.1))

                    VStack(spacing: 8) {
                        Text(interpretation.status)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(interpretation.info)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 5)
                }
                .padding(25)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(interpretation.color.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 15) {
                    Text("Frequency Details")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.leading, 5)

                    ForEach(frequencies, id: \.self) { freq in
                        let val = (results[freq] ?? 0) * 100
                        HStack {
                            Text("\(freq) Hz")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(String(format: "%.1f", val)) dB")
                                .bold()
                                .foregroundColor(val > 25 ? .orange : .mint)
                        }
                        .padding()
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Button(action: onReset) {
                    Text("Restart Test")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.mint)
                        .cornerRadius(12)
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
    }
}
