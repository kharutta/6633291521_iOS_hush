import SwiftUI

struct ResultSummaryView: View {
    let results: [Int: Float]
    let frequencies: [Int]
    var onReset: () -> Void

    private var averageIndex: Float {
        let coreFreqs = [500, 1000, 2000, 4000]
        let sum = coreFreqs.reduce(0) { $0 + (results[$1] ?? 0) }
        return (sum / Float(coreFreqs.count)) * 100
    }

    private func interpretIndex(_ avg: Float) -> (status: String, info: String, color: Color) {
        switch avg {
        case ..<16:
            return ("Excellent (Normal)", "You can hear soft sounds easily in this test setup.", .mint)
        case 16..<26:
            return ("Slightly Reduced", "You may miss very quiet sounds in some situations.", .green)
        case 26..<41:
            return ("Mild Reduction", "Soft speech or distant sounds may be hard to hear.", .orange)
        case 41..<56:
            return ("Moderate Reduction", "Conversational speech may sound faint.", .red)
        case 56..<71:
            return ("Moderately-Severe", "You might struggle with most everyday sounds.", .red)
        case 71..<91:
            return ("Severe", "Only loud tones in this test are easily heard.", .purple)
        default:
            return ("Profound", "Almost all tones in this test are difficult to hear.", .purple)
        }
    }

    var body: some View {
        let interpretation = interpretIndex(averageIndex)

        ScrollView {
            VStack(spacing: 25) {
                Text("Test Results")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Results are relative and may vary depending on your device, headphones, and environment.")
                    .font(.footnote)
                    .foregroundColor(.mint)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)

                VStack(spacing: 15) {
                    Text("Average Hearing Index")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("\(String(format: "%.1f", averageIndex))")
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
                            Text("\(String(format: "%.1f", val))")
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
