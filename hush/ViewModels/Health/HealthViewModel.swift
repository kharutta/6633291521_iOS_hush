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
    var extendedData: [DailyDose] = []
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

    var isFullyRecovered: Bool { recoveryPercent >= 99 }

    var weeklyAvgDose: Double {
        guard !weeklyData.isEmpty else { return 0 }
        return weeklyData.map(\.value).reduce(0, +) / Double(weeklyData.count)
    }

    var longTermAvgDose: Double {
        guard !extendedData.isEmpty else { return 0 }
        return extendedData.map(\.value).reduce(0, +) / Double(extendedData.count)
    }

    var hearingAge: HearingAgeEstimate {
        estimateHearingAge(
            actualAge: actualAge,
            yearsWearing: yearsWearing,
            hoursPerDay: hoursPerDay,
            volumeLevel: volumeLevel,
            avgDose: longTermAvgDose
        )
    }

    var weeklyListenedHours: Double {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())!.start
        let weekDays = extendedData.filter { $0.date >= startOfWeek }
        return weekDays.reduce(0.0) { $0 + $1.totalSeconds } / 3600
    }

    var monthlyListenedHours: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())!.start
        let monthlyDays = extendedData.filter { $0.date >= startOfMonth }
        return monthlyDays.reduce(0.0) { $0 + $1.totalSeconds } / 3600
    }

    var safeDaysStreak: Int {
        var streak = 0
        for day in extendedData.reversed() {
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
        await loadData()
    }

    func loadData() async {
        do {
            let calendar = Calendar.current
            let hkData = try await hk.fetchDailyAverages(pastDays: 90)

            let earliestDate = calendar.date(byAdding: .day, value: -90, to: Date())!

            var manualByDay: [Date: [ManualSession]] = [:]
            for session in manualSessions {
                guard session.startTime >= earliestDate else { continue }
                let day = calendar.startOfDay(for: session.startTime)
                manualByDay[day, default: []].append(session)
            }

            var results: [DailyDose] = []

            for dayData in hkData {
                let targetDate = dayData.date
                var totalDose = dayData.value
                var totalWeightedDB = dayData.avgDB * dayData.totalSeconds
                var totalSeconds = dayData.totalSeconds

                if let manualForDay = manualByDay[targetDate] {
                    for session in manualForDay {
                        let duration = session.endTime.timeIntervalSince(session.startTime)
                        totalDose += sampleDosePercent(dB: session.volume, durationSeconds: duration)
                        totalWeightedDB += (session.volume * duration)
                        totalSeconds += duration
                    }
                }

                let finalAvgDB = totalSeconds > 0 ? (totalWeightedDB / totalSeconds) : 0

                results.append(DailyDose(
                    date: targetDate,
                    day: dayData.day,
                    value: totalDose,
                    avgDB: finalAvgDB,
                    totalSeconds: totalSeconds
                ))
            }

            self.extendedData = results
            self.weeklyData = Array(results.suffix(7))
        } catch {
            print("[HealthView] data error:", error)
        }
        isLoading = false
    }
}
