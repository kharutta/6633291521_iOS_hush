import SwiftUI
import SwiftData
import HealthKit

struct TodayView: View {
    @State private var hk = HearingHealthManager()
    @Query private var manualSessions: [ManualSession]

    private var todayManualSessions: [ManualSession] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return manualSessions.filter { $0.startTime >= startOfDay }
    }

    private var unifiedSessions: [UnifiedSession] {
        let hkSessions = hk.sessions.map { UnifiedSession(from: $0) }
        let manualUnified = todayManualSessions.map { UnifiedSession(from: $0) }
        return (hkSessions + manualUnified).sorted { $0.startDate < $1.startDate }
    }

    private var totalDose: Double {
        unifiedSessions.reduce(0) { $0 + $1.dosePercent }
    }

    private var avgDB: Double {
        guard !unifiedSessions.isEmpty else { return 0 }
        return unifiedSessions.map(\.dB).reduce(0, +) / Double(unifiedSessions.count)
    }

    private var dosePercent: Double { min(totalDose, 100) }
    private var headroom: Double { max(0, 100 - totalDose) }
    private var ringProgress: CGFloat { CGFloat(dosePercent / 100) }

    private var listenedHours: Double {
        unifiedSessions.reduce(0) { $0 + $1.durationSeconds } / 3600
    }

    private var safeUntilText: String {
        guard avgDB > 0 else { return "—" }
        let date = safeUntil(currentDose: totalDose, avgDB: avgDB)
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h a"
        
        if calendar.component(.hour, from: date) == 23 && calendar.component(.minute, from: date) > 50 {
            return "12 AM"
        }
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
                Text("Today's Dose").font(.headline)

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

                        Text(String(format: "%.1f%%", totalDose))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(ringColor)
                            .contentTransition(.numericText())

                        if totalDose >= 100 {
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
                        value: avgDB > 0 ? "\(Int(avgDB)) dB" : "—",
                        valueColor: .mint
                    )
                    StatBox(
                        label: "safe until",
                        value: safeUntilText,
                        valueColor: .mint
                    )
                }

                Text("Sessions").font(.headline)

                if unifiedSessions.isEmpty {
                    Text("No headphone sessions today")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                } else {
                    ForEach(unifiedSessions) { session in
                        SessionRow(
                            title: session.source,
                            sub: sessionSubtitle(session),
                            percent: String(format: "%.1f%%", session.dosePercent)
                        )
                        .overlay(
                            session.isManual ?
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.mint)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    .padding(8)
                                : nil
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

    private func sessionSubtitle(_ session: UnifiedSession) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm"
        let start = fmt.string(from: session.startDate)
        let end = fmt.string(from: session.endDate)
        let activityText = session.activity != nil ? " • \(session.activity!)" : ""
        return "\(start)-\(end) • \(Int(session.dB)) dB\(activityText)"
    }
}
