import SwiftUI
import Charts
import HealthKit

struct HistoryView: View {
    @State private var hk = HearingHealthManager()
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

        // Sun=0,...,Sat=6
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols

        var weekdayDoses: [Double] = []
        var weekendDoses: [Double] = []

        for dose in dailyData {
            if let idx = symbols.firstIndex(of: dose.day) {
                if idx == 0 || idx == 7 {
                    weekendDoses.append(dose.value)
                } else {
                    weekdayDoses.append(dose.value)
                }
            }
        }

        let wdAvg = weekdayDoses.isEmpty ? 0 : weekdayDoses.reduce(0, +) / Double(weekdayDoses.count)
        let weAvg = weekendDoses.isEmpty ? 0 : weekendDoses.reduce(0, +) / Double(weekendDoses.count)

        guard weAvg > 0, wdAvg > 0 else { return nil }

        if wdAvg > weAvg * 1.2 {
            let ratio = (wdAvg / weAvg)
            return InsightData(
                color: .yellow,
                text: String(format: "weekdays %.1f× higher — likely commute + work", ratio)
            )
        } else if weAvg > wdAvg * 1.2 {
            let ratio = (weAvg / wdAvg)
            return InsightData(
                color: .yellow,
                text: String(format: "weekends %.1f× higher — likely leisure listening", ratio)
            )
        }
        return nil
    }

    private var trendInsight: InsightData? {
        guard dailyData.count >= 4 else { return nil }
        let half = dailyData.count / 2
        let older = dailyData.prefix(half).map(\.value).reduce(0, +) / Double(half)
        let newer = dailyData.suffix(half).map(\.value).reduce(0, +) / Double(half)

        if newer < older * 0.9 {
            return InsightData(color: .green, text: "improving vs last week 📉")
        } else if newer > older * 1.1 {
            return InsightData(color: .red, text: "getting worse vs last week 📈")
        }
        return InsightData(color: .blue, text: "stable vs last week")
    }

    private var volumeInsight: InsightData? {
        guard weeklyAvg > 20 else { return nil }
        return InsightData(
            color: .blue,
            text: "lower by 3 dB → cuts weekly dose by ~50%"
        )
    }

    private var insights: [InsightData] {
        [weekdayWeekendInsight, trendInsight, volumeInsight].compactMap { $0 }
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
                                    x: .value("Day", item.day),
                                    y: .value("Dose", item.value),
                                    width: .fixed(40)
                                )
                                .foregroundStyle(item.color)
                                .cornerRadius(4)
                            }
                            RuleMark(y: .value("Limit", 100))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(.red.opacity(0.5))
                        }
                        .frame(height: 120)
                        .chartYAxis(.hidden)
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(.gray)
                                    .font(.caption2)
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
                        value: dailyData.isEmpty ? "—" : "\(Int(weeklyAvg))%",
                        valueColor: weeklyAvg > 60 ? .red : weeklyAvg > 40 ? .orange : .mint
                    )
                    if let worst = worstDay {
                        StatBox(
                            label: "worst day",
                            value: "\(worst.day) \(Int(worst.value))%",
                            valueColor: .red
                        )
                    } else {
                        StatBox(label: "worst day", value: "—", valueColor: .gray)
                    }
                }

                if !insights.isEmpty {
                    Text("Insights").font(.headline)
                    ForEach(insights) { insight in
                        InsightRow(color: insight.color, text: insight.text)
                    }
                }
            }
            .padding()
        }
        .task {
            try? await hk.requestAuthorization()
            do {
                dailyData = try await hk.fetchDailyAverages(pastDays: 7)
            } catch {
                print("History fetch error:", error)
            }
            isLoading = false
        }
    }
}
