import SwiftUI
import HealthKit

@MainActor
@Observable
class HistoryViewModel {
    private var hk = HearingHealthManager()
    private var manualSessions: [ManualSession] = []
    var dailyData: [DailyDose] = []
    var lastWeekData: [DailyDose] = []
    var isLoading = true

    var weeklyAvg: Double {
        guard !dailyData.isEmpty else { return 0 }
        return dailyData.map(\.value).reduce(0, +) / Double(dailyData.count)
    }

    var worstDay: DailyDose? {
        dailyData.max(by: { $0.value < $1.value })
    }

    var weekdayWeekendInsight: InsightData? {
        guard dailyData.count == 7 else { return nil }

        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols

        var weekdayDoses: [Double] = []
        var weekendDoses: [Double] = []

        for dose in dailyData {
            if let idx = symbols.firstIndex(of: dose.day) {
                if idx == 0 || idx == 6 {
                    weekendDoses.append(dose.value)
                } else {
                    weekdayDoses.append(dose.value)
                }
            }
        }

        let wdAvg = weekdayDoses.isEmpty ? 0 : weekdayDoses.reduce(0, +) / Double(weekdayDoses.count)
        let weAvg = weekendDoses.isEmpty ? 0 : weekendDoses.reduce(0, +) / Double(weekendDoses.count)

        guard wdAvg > 0 || weAvg > 0 else { return nil }
        let maxAvg = max(wdAvg, weAvg)
        guard maxAvg > 0 else { return nil }

        if wdAvg > weAvg * 1.2 {
            let ratio = wdAvg / max(weAvg, 1)
            return InsightData(
                color: .orange,
                title: String(format: "weekdays %.1f× higher", ratio),
                subtitle: "likely commute + work"
            )
        } else if weAvg > wdAvg * 1.2 {
            let ratio = weAvg / max(wdAvg, 1)
            return InsightData(
                color: .orange,
                title: String(format: "weekends %.1f× higher", ratio),
                subtitle: "likely leisure listening"
            )
        }
        return nil
    }

    var trendInsight: InsightData? {
        guard dailyData.count >= 3, lastWeekData.count >= 3 else { return nil }

        let thisWeekAvg = dailyData.map(\.value).reduce(0, +) / Double(dailyData.count)
        let lastWeekAvg = lastWeekData.map(\.value).reduce(0, +) / Double(lastWeekData.count)

        guard thisWeekAvg > 0 || lastWeekAvg > 0 else { return nil }

        if thisWeekAvg < lastWeekAvg * 0.85 && lastWeekAvg > 0 {
            return InsightData(
                color: .teal,
                title: "improving vs last week",
                subtitle: String(format: "avg %.1f%% → %.1f%%", lastWeekAvg, thisWeekAvg)
            )
        } else if thisWeekAvg > lastWeekAvg * 1.15 {
            return InsightData(
                color: .teal,
                title: "getting worse vs last week",
                subtitle: String(format: "avg %.1f%% → %.1f%%", lastWeekAvg, thisWeekAvg)
            )
        }
        return nil
    }

    var volumeInsight: InsightData? {
        guard weeklyAvg > 100 else { return nil }

        let dBReduction = 3 * log2(weeklyAvg / 100)
        let doseReductionPercent = (weeklyAvg - 100) / weeklyAvg * 100

        return InsightData(
            color: .blue,
            title: String(format: "lower by %.0f dB", ceil(dBReduction)),
            subtitle: String(format: "cuts weekly dose ~%.0f%%", doseReductionPercent)
        )
    }

    var insights: [InsightData] {
        [weekdayWeekendInsight, trendInsight, volumeInsight].compactMap { $0 }
    }

    var maxDB: Double {
        let maxValue = dailyData.map(\.avgDB).max() ?? 0
        return maxValue
    }

    func updateManualSessions(_ sessions: [ManualSession]) {
        manualSessions = sessions
    }

    func initialize() async {
        try? await hk.requestAuthorization()
        await loadCombinedData()
    }

    func loadCombinedData() async {
        do {
            let calendar = Calendar.current
            let today = Date()

            let hkDailyData = try await hk.fetchDailyAverages(pastDays: 14)

            let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: calendar.startOfDay(for: today))!

            var manualByDay: [Date: [ManualSession]] = [:]
            for session in manualSessions {
                guard session.startTime >= fourteenDaysAgo else { continue }
                let day = calendar.startOfDay(for: session.startTime)
                manualByDay[day, default: []].append(session)
            }

            var results: [DailyDose] = []

            for dayData in hkDailyData {
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

            self.lastWeekData = Array(results.dropLast(7).suffix(7))
            self.dailyData = Array(results.suffix(7))
        } catch {
            print("History fetch error:", error)
        }
        isLoading = false
    }
}
