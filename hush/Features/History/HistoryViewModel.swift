import SwiftUI
import HealthKit

@MainActor
@Observable
class HistoryViewModel {
    private var hk = HearingHealthManager()
    private var manualSessions: [ManualSession] = []
    var dailyData: [DailyDose] = []
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
        guard dailyData.count == 7 else { return nil }

        let half = dailyData.count / 2
        let olderDays = Array(dailyData.prefix(half))
        let newerDays = Array(dailyData.suffix(half))

        let olderAvg = olderDays.map(\.value).reduce(0, +) / Double(half)
        let newerAvg = newerDays.map(\.value).reduce(0, +) / Double(half)

        guard olderAvg > 0 || newerAvg > 0 else { return nil }

        if newerAvg < olderAvg * 0.85 && olderAvg > 0 {
            return InsightData(
                color: .teal,
                title: "improving vs earlier this week",
                subtitle: String(format: "avg %.0f%% → %.0f%%", olderAvg, newerAvg)
            )
        } else if newerAvg > olderAvg * 1.15 {
            return InsightData(
                color: .teal,
                title: "getting worse vs earlier this week",
                subtitle: String(format: "avg %.0f%% → %.0f%%", olderAvg, newerAvg)
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
        let maxValue = dailyData.map(\.avgDB).max() ?? 85
        return max(maxValue, 90)
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
            let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: today)!.start
            let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek)!
            let daysSinceLastWeekStart = calendar.dateComponents([.day], from: startOfLastWeek, to: today).day! + 1

            let hkDailyData = try await hk.fetchDailyAverages(pastDays: daysSinceLastWeekStart)

            var manualByDay: [Date: [ManualSession]] = [:]
            for session in manualSessions {
                guard session.startTime >= startOfLastWeek else { continue }
                let day = calendar.startOfDay(for: session.startTime)
                manualByDay[day, default: []].append(session)
            }

            var results: [DailyDose] = []

            for dayData in hkDailyData {
                let targetDate = dayData.date
                var totalDose = dayData.value

                var totalWeightedDB = dayData.avgDB * 3600
                var totalSeconds: Double = 3600

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
                    avgDB: finalAvgDB
                ))
            }

            self.dailyData = Array(results.suffix(7))
        } catch {
            print("History fetch error:", error)
        }
        isLoading = false
    }
}
