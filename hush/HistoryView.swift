import SwiftUI
import SwiftData
import Charts
import HealthKit

struct HistoryView: View {
    @State private var hk = HearingHealthManager()
    @Query private var manualSessions: [ManualSession]
    @State private var dailyData: [DailyDose] = []
    @State private var isLoading = true

    private var weeklyAvg: Double {
        guard !dailyData.isEmpty else { return 0 }
        return dailyData.map(\.value).reduce(0, +) / Double(dailyData.count)
    }

    private var worstDay: DailyDose? {
        dailyData.max(by: { $0.value < $1.value })
    }

    private var weekdayWeekendInsight: InsightData? {
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

    private var trendInsight: InsightData? {
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

    private var volumeInsight: InsightData? {
        guard weeklyAvg > 100 else { return nil }
        
        let dBReduction = 3 * log2(weeklyAvg / 100)
        let doseReductionPercent = (weeklyAvg - 100) / weeklyAvg * 100

        return InsightData(
            color: .blue,
            title: String(format: "lower by %.0f dB", ceil(dBReduction)),
            subtitle: String(format: "cuts weekly dose ~%.0f%%", doseReductionPercent)
        )
    }
    
    private var insights: [InsightData] {
        [weekdayWeekendInsight, trendInsight, volumeInsight].compactMap { $0 }
    }
    
    private var maxDB: Double {
        let maxValue = dailyData.map(\.avgDB).max() ?? 85
        return max(maxValue, 90)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Past 7 days").font(.headline)

                VStack(alignment: .leading) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if dailyData.isEmpty {
                        Text("No data found")
                            .font(.caption).foregroundColor(.gray)
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        Chart {
                            ForEach(dailyData) { item in
                                BarMark(
                                    x: .value("Day", item.date, unit: .day),
                                    y: .value("Decibels", item.avgDB),
                                    width: .fixed(35)
                                )
                                .foregroundStyle(item.color)
                                .cornerRadius(4)
                                .annotation(position: .top, spacing: 8) {
                                    if item.avgDB > 0 {
                                        Text(String(format: "%.0f", item.avgDB))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                            
                            RuleMark(y: .value("Limit", 85))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(.red.opacity(0.5))
                        }
                        .frame(height: 160)
                        .padding(.top, 24)
                        .chartYScale(domain: 0...max(100, maxDB + 10))
                        .chartYAxis(.hidden)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                HStack {
                    StatBox(
                        label: "weekly avg",
                        value: dailyData.isEmpty ? "—" : "\(String(format: "%.1f%", weeklyAvg))%",
                        valueColor: weeklyAvg > 60 ? .red : weeklyAvg > 40 ? .orange : .mint
                    )
                    if let worst = worstDay {
                        StatBox(
                            label: "worst day",
                            value: "\(worst.day) \(String(format: "%.1f%", worst.value))%",
                            valueColor: .red
                        )
                    } else {
                        StatBox(label: "worst day", value: "—", valueColor: .gray)
                    }
                }

                if !insights.isEmpty {
                    Text("Insights").font(.headline)
                    ForEach(insights) { insight in
                        InsightRow(color: insight.color, title: insight.title, subtitle: insight.subtitle)
                    }
                }
            }
            .padding()
        }
        .task {
            try? await hk.requestAuthorization()
            await loadCombinedData()
        }
    }

    private func loadCombinedData() async {
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
