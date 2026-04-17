import SwiftUI

struct HearingAgeCard: View {
    let estimate: HearingAgeEstimate
    let volumeLevel: String
    let yearsWearing: Int

    var ageColor: Color {
        let diff = estimate.difference
        if diff >= 5 { return .red }
        if diff >= 2 { return .orange }
        return .mint
    }

    private var breakdownText: String {
        let preRounded = Int(estimate.preAppBoost.rounded())
        let recentRounded = Int(estimate.recentBoost.rounded())
        var parts: [String] = []
        if preRounded > 0 {
            parts.append("\(preRounded) yr\(preRounded == 1 ? "" : "s") from \(yearsWearing)-yr history at \(volumeLevel.lowercased()) volume")
        }
        if recentRounded > 0 {
            parts.append("\(recentRounded) yr\(recentRounded == 1 ? "" : "s") from recent listening")
        }
        return parts.isEmpty ? "your listening habits look safe" : parts.joined(separator: " + ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(estimate.estimatedAge)")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(ageColor)
                    Text("estimated hearing age")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()

                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(estimate.actualAge)")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    Text("actual age")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 6)
            }

            Divider().background(Color.gray.opacity(0.25))

            Text(breakdownText)
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)

            Text("Based on your listening history + HealthKit data using ISO 1999 — not a medical diagnosis")
                .font(.caption2)
                .foregroundColor(Color.gray.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
    }
}
