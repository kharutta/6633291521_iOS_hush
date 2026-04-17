import SwiftUI
import SwiftData

struct HealthView: View {
    @State private var viewModel = HealthViewModel()
    @Query private var manualSessions: [ManualSession]

    @AppStorage("birthDate") private var birthDateInterval: Double = Date().timeIntervalSince1970
    @AppStorage("yearsWearing") private var yearsWearing: Int = 0
    @AppStorage("hoursPerDay") private var hoursPerDay: Int = 0
    @AppStorage("volumeLevel") private var volumeLevel: String = "Medium"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Hearing Age")
                    .font(.headline)

                HearingAgeCard(estimate: viewModel.hearingAge, volumeLevel: volumeLevel, yearsWearing: yearsWearing)

                Text("Ear Recovery")
                    .font(.headline)

                EarRecoveryCard(
                    recoveryPercent: viewModel.recoveryPercent,
                    hoursToFullRecovery: viewModel.hoursToFullRecovery,
                    isFullyRecovered: viewModel.isFullyRecovered
                )

                Text("Cumulative Stats")
                    .font(.headline)

                VStack(spacing: 0) {
                    CumulativeStatRow(label: "this week", value: String(format: "%.1f hrs", viewModel.weeklyListenedHours))
                    Divider().background(Color.gray.opacity(0.2))
                    CumulativeStatRow(label: "this month", value: String(format: "%.1f hrs", viewModel.monthlyListenedHours))
                    Divider().background(Color.gray.opacity(0.2))
                    CumulativeStatRow(label: "safe days streak", value: "\(viewModel.safeDaysStreak) days")
                }
                .background(Color.white.opacity(0.07))
                .cornerRadius(12)
            }
            .padding()
        }
        .task {
            viewModel.updateAppStorage(
                birthDateInterval: birthDateInterval,
                yearsWearing: yearsWearing,
                hoursPerDay: hoursPerDay,
                volumeLevel: volumeLevel
            )
            await viewModel.initialize()
        }
        .onChange(of: manualSessions) { _, newValue in
            viewModel.updateManualSessions(newValue)
        }
        .onChange(of: birthDateInterval) { _, newValue in
            viewModel.birthDateInterval = newValue
        }
        .onChange(of: yearsWearing) { _, newValue in
            viewModel.yearsWearing = newValue
        }
        .onChange(of: hoursPerDay) { _, newValue in
            viewModel.hoursPerDay = newValue
        }
        .onChange(of: volumeLevel) { _, newValue in
            viewModel.volumeLevel = newValue
        }
    }
}
