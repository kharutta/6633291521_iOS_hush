import SwiftUI
import HealthKit

@MainActor
@Observable
class HealthViewModel {
    private var hk = HearingHealthManager()
    private var manualSessions: [ManualSession] = []

    var birthDateInterval: Double = Date().timeIntervalSince1970
    var yearsWearing: Int = 0
    var hoursPerDay: Int = 0
    var volumeLevel: String = "Medium"

    var weeklyData: [DailyDose] = []
    var isLoading = true

    var actualAge: Int {
        let birthDate = Date(timeIntervalSince1970: birthDateInterval)
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }

    var lastSessionDate: Date? {
        let allSessions: [Date] = hk.sessions.map(\.endDate) +
            manualSessions.map(\.endTime)
        return allSessions.max()
    }

    var hoursSinceLastSession: Double {
        guard let last = lastSessionDate else { return 999 }
        return Date().timeIntervalSince(last) / 3600
    }
    
    var todayDosePercent: Double {
        let hkDose = totalDosePercent(samples: hk.sessions)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let manualDose = manualSessions
            .filter { $0.startTime >= startOfDay }
            .reduce(0.0) { $0 + sampleDosePercent(dB: $1.volume, durationSeconds: $1.endTime.timeIntervalSince($1.startTime)) }
        return hkDose + manualDose
    }
    
    var recoveryPercent: Double {
        ttsRecoveryPercent(
            hoursSinceLastSession: hoursSinceLastSession,
            todayDosePercent: todayDosePercent)
    }

    var hoursToFullRecovery: Double {
        hoursUntilFullyRecovered(
            hoursSinceLastSession: hoursSinceLastSession,
            todayDosePercent: todayDosePercent
        )
    }

    var isFullyRecovered: Bool { recoveryPercent >= 95 }

    var weeklyAvgDose: Double {
        guard !weeklyData.isEmpty else { return 0 }
        return weeklyData.map(\.value).reduce(0, +) / Double(weeklyData.count)
    }

    var hearingAge: HearingAgeEstimate {
        estimateHearingAge(
            actualAge: actualAge,
            yearsWearing: yearsWearing,
            hoursPerDay: hoursPerDay,
            volumeLevel: volumeLevel,
            weeklyAvgDose: weeklyAvgDose
        )
    }

    var weeklyListenedHours: Double {
        let hkHours = hk.sessions.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } / 3600
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())!.start
        let manualHours = manualSessions
            .filter { $0.startTime >= startOfWeek }
            .reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) } / 3600
        return hkHours + manualHours
    }

    var monthlyListenedHours: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())!.start
        let manualHours = manualSessions
            .filter { $0.startTime >= startOfMonth }
            .reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) } / 3600
        return manualHours + (weeklyListenedHours * 4.3)
    }

    var safeDaysStreak: Int {
        guard !weeklyData.isEmpty else { return 0 }
        var streak = 0
        for day in weeklyData.reversed() {
            if day.value < 100 { streak += 1 } else { break }
        }
        return streak
    }

    func updateManualSessions(_ sessions: [ManualSession]) {
        manualSessions = sessions
    }

    func updateAppStorage(birthDateInterval: Double, yearsWearing: Int, hoursPerDay: Int, volumeLevel: String) {
        self.birthDateInterval = birthDateInterval
        self.yearsWearing = yearsWearing
        self.hoursPerDay = hoursPerDay
        self.volumeLevel = volumeLevel
    }

    func initialize() async {
        try? await hk.requestAuthorization()
        await hk.loadToday()
        await loadWeeklyData()
    }

    func loadWeeklyData() async {
        do {
            weeklyData = try await hk.fetchDailyAverages(pastDays: 7)
        } catch {
            print("[HealthView] weekly data error:", error)
        }
        isLoading = false
    }
}
