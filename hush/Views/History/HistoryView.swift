import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @Query private var manualSessions: [ManualSession]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Past 7 Days").font(.headline)

                VStack(alignment: .leading) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if viewModel.dailyData.isEmpty {
                        Text("No data found")
                            .font(.caption).foregroundColor(.gray)
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        Chart {
                            ForEach(viewModel.dailyData) { item in
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
                        .chartYScale(domain: 0...max(100, viewModel.maxDB + 10))
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
                        value: viewModel.dailyData.isEmpty ? "—" : "\(String(format: "%.1f%", viewModel.weeklyAvg))%",
                        valueColor: viewModel.weeklyAvg > 60 ? .red : viewModel.weeklyAvg > 40 ? .orange : .mint
                    )
                    if let worst = viewModel.worstDay {
                        StatBox(
                            label: "worst day",
                            value: "\(worst.day) \(String(format: "%.1f%", worst.value))%",
                            valueColor: .red
                        )
                    } else {
                        StatBox(label: "worst day", value: "—", valueColor: .gray)
                    }
                }

                if !viewModel.insights.isEmpty {
                    Text("Insights").font(.headline)
                    ForEach(viewModel.insights) { insight in
                        InsightRow(color: insight.color, title: insight.title, subtitle: insight.subtitle)
                    }
                }
            }
            .padding()
        }
        .task {
            await viewModel.initialize()
        }
        .onChange(of: manualSessions) { _, newValue in
            viewModel.updateManualSessions(newValue)
        }
    }
}
