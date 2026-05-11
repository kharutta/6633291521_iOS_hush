import SwiftUI
import SwiftData

struct TodayView: View {
    @State private var viewModel = TodayViewModel()
    @Query private var manualSessions: [ManualSession]

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
                                .trim(from: 0, to: viewModel.ringProgress)
                                .stroke(viewModel.ringColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 0.8), value: viewModel.ringProgress)
                            Image(systemName: "ear.badge.waveform")
                                .font(.system(size: 100))
                        }

                        Text(String(format: "%.1f%%", viewModel.totalDose))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(viewModel.ringColor)
                            .contentTransition(.numericText())

                        if viewModel.totalDose >= 100 {
                            Text("⚠️ daily limit reached")
                                .font(.caption).foregroundColor(.red)
                        } else {
                            Text("\(Int(viewModel.headroom))% headroom left")
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
                        value: viewModel.listenedHours > 0 ? String(format: "%.1f hr", viewModel.listenedHours) : "—",
                        valueColor: .mint
                    )
                    StatBox(
                        label: "avg dB",
                        value: viewModel.avgDB > 0 ? "\(Int(viewModel.avgDB)) dB" : "—",
                        valueColor: .mint
                    )
                    StatBox(
                        label: "safe until",
                        value: viewModel.safeUntilText,
                        valueColor: .mint
                    )
                }

                Text("Sessions").font(.headline)

                if viewModel.unifiedSessions.isEmpty {
                    Text("No headphone sessions today")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.unifiedSessions) { session in
                        SessionRow(
                            title: session.source,
                            sub: viewModel.sessionSubtitle(session),
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
            await viewModel.initialize()
        }
        .onChange(of: manualSessions) { _, newValue in
            viewModel.updateManualSessions(newValue)
        }
    }
}
