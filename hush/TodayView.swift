import SwiftUI
import HealthKit

struct TodayView: View {
    @State private var hk = HearingHealthManager()

    private var dosePercent: Double { min(hk.totalDose, 100) }
    private var headroom: Double { max(0, 100 - hk.totalDose) }
    private var ringProgress: CGFloat { CGFloat(dosePercent / 100) }

    private var listenedHours: Double {
        hk.sessions.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } / 3600
    }

    private var safeUntilText: String {
        guard hk.avgDB > 0 else { return "—" }
        let date = safeUntil(currentDose: hk.totalDose, avgDB: hk.avgDB)
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }

    private var ringColor: Color {
        if dosePercent > 85 { return .red }
        if dosePercent > 60 { return .orange }
        return .mint
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Today's dose").font(.headline)

                HStack {
                    Spacer()
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                            Circle()
                                .trim(from: 0, to: ringProgress)
                                .stroke(ringColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 0.8), value: ringProgress)
                            Image(systemName: "ear.badge.waveform")
                                .font(.system(size: 100))
                        }

                        Text("\(Int(dosePercent))%")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(ringColor)
                            .contentTransition(.numericText())

                        if hk.totalDose >= 100 {
                            Text("⚠️ daily limit reached")
                                .font(.caption).foregroundColor(.red)
                        } else {
                            Text("\(Int(headroom))% headroom left")
                                .font(.caption).foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 15)
                    .frame(height: 300)
                    .padding()
                    Spacer()
                }
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                HStack {
                    StatBox(
                        label: "listened",
                        value: listenedHours > 0 ? String(format: "%.1f hr", listenedHours) : "—",
                        valueColor: .mint
                    )
                    StatBox(
                        label: "avg dB",
                        value: hk.avgDB > 0 ? "\(Int(hk.avgDB)) dB" : "—",
                        valueColor: .mint
                    )
                    StatBox(
                        label: "safe until",
                        value: safeUntilText,
                        valueColor: .mint
                    )
                }

                Text("sessions").font(.headline)

                if hk.sessions.isEmpty {
                    Text("No headphone sessions today")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                } else {
                    ForEach(hk.sessions, id: \.uuid) { session in
                        SessionRow(
                            title: session.sourceRevision.source.name,
                            sub: sessionSubtitle(session),
                            percent: String(format: "%.0f%%", sessionDosePercent(session))
                        )
                    }
                }
            }
            .padding()
        }
        .task {
            try? await hk.requestAuthorization()
            await hk.loadToday()
        }
    }

    private func sessionSubtitle(_ sample: HKQuantitySample) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm"
        let start = fmt.string(from: sample.startDate)
        let end = fmt.string(from: sample.endDate)
        let dB = sample.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel())
        return "\(start)-\(end) • \(Int(dB)) dB"
    }

    private func sessionDosePercent(_ sample: HKQuantitySample) -> Double {
        let dB = sample.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel())
        let duration = sample.endDate.timeIntervalSince(sample.startDate)
        return sampleDosePercent(dB: dB, durationSeconds: duration)
    }
}
