import SwiftUI

struct EarRecoveryCard: View {
    let recoveryPercent: Double
    let hoursToFullRecovery: Double
    let isFullyRecovered: Bool

    private var recoveryColor: Color {
        if recoveryPercent >= 95 { return .mint }
        if recoveryPercent >= 60 { return .mint }
        return .orange
    }

    private var recoveryLabel: String {
        "recovered since last session"
    }

    private var subtitleText: String {
        if isFullyRecovered { return "your hearing has fully recovered" }
        let hrs = hoursToFullRecovery
        if hrs < 1 { return "fully recovered in < 1 hr" }
        return String(format: "fully recovered in ~%.0f hrs", ceil(hrs))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(recoveryLabel)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%.0f%%", recoveryPercent))
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(recoveryColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(recoveryColor)
                        .frame(width: geo.size.width * CGFloat(min(recoveryPercent / 100, 1.0)), height: 10)
                        .animation(.easeOut(duration: 1.0), value: recoveryPercent)
                }
            }
            .frame(height: 10)

            Text(subtitleText)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
