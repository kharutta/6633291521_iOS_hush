import SwiftUI
import HealthKit

@MainActor
@Observable
class TodayViewModel {
    private var hk = HearingHealthManager()
    private var manualSessions: [ManualSession] = []

    var todayManualSessions: [ManualSession] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return manualSessions.filter { $0.startTime >= startOfDay }
    }

    var unifiedSessions: [UnifiedSession] {
        let hkSessions = hk.sessions.map { UnifiedSession(from: $0) }
        let manualUnified = todayManualSessions.map { UnifiedSession(from: $0) }
        return (hkSessions + manualUnified).sorted { $0.startDate < $1.startDate }
    }

    var totalDose: Double {
        unifiedSessions.reduce(0) { $0 + $1.dosePercent }
    }

    var avgDB: Double {
        guard !unifiedSessions.isEmpty else { return 0 }
        return unifiedSessions.map(\.dB).reduce(0, +) / Double(unifiedSessions.count)
    }

    var dosePercent: Double { min(totalDose, 100) }
    var headroom: Double { max(0, 100 - totalDose) }
    var ringProgress: CGFloat { CGFloat(dosePercent / 100) }

    var listenedHours: Double {
        unifiedSessions.reduce(0) { $0 + $1.durationSeconds } / 3600
    }

    var safeUntilText: String {
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

    var ringColor: Color {
        if dosePercent > 85 { return .red }
        if dosePercent > 60 { return .orange }
        return .mint
    }

    func sessionSubtitle(_ session: UnifiedSession) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm"
        let start = fmt.string(from: session.startDate)
        let end = fmt.string(from: session.endDate)
        let activityText = session.activity != nil ? " • \(session.activity!)" : ""
        return "\(start)-\(end) • \(Int(session.dB)) dB\(activityText)"
    }

    func updateManualSessions(_ sessions: [ManualSession]) {
        manualSessions = sessions
    }

    func initialize() async {
        try? await hk.requestAuthorization()
        await hk.loadToday()
    }
}
