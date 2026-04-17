import SwiftUI
import SwiftData
import HealthKit

func ttsRecoveryPercent(hoursSinceLastSession: Double) -> Double {
    guard hoursSinceLastSession >= 0 else { return 0 }
    let halfLife: Double = 16.0
    return (1.0 - pow(0.5, hoursSinceLastSession / halfLife)) * 100.0
}

func hoursUntilFullyRecovered(currentRecoveryPercent: Double) -> Double {
    let target = 0.95
    let current = currentRecoveryPercent / 100.0
    guard current < target else { return 0 }
    let halfLife: Double = 16.0
    let totalHours = halfLife * log2(1.0 / (1.0 - target))
    let elapsed = current > 0 ? halfLife * log2(1.0 / (1.0 - current)) : 0
    return max(0, totalHours - elapsed)
}

struct HearingAgeEstimate {
    let estimatedAge: Int
    let actualAge: Int
    let preAppBoost: Double
    let recentBoost: Double
    var difference: Int { estimatedAge - actualAge }
}

func volumeLevelToDecibels(_ level: String) -> Double {
    switch level {
    case "Low":  return 65.0
    case "High": return 85.0
    default:     return 75.0
    }
}

func estimateHearingAge(
    actualAge: Int,
    yearsWearing: Int,
    hoursPerDay: Int,
    volumeLevel: String,
    weeklyAvgDose: Double
) -> HearingAgeEstimate {
    let dB = volumeLevelToDecibels(volumeLevel)
    let dailyDosePercent = (Double(hoursPerDay) / allowedHours(dB: dB)) * 100.0
    let excessDailyDose = max(0, dailyDosePercent - 50.0)
    let preAppBoost = (excessDailyDose / 100.0) * Double(yearsWearing) * 0.05 * 100

    let recentExcess = max(0, weeklyAvgDose - 50.0)
    let recentBoost = (recentExcess / 100.0) * (0.05 / 52.0) * 100

    let totalBoost = preAppBoost + recentBoost
    let estimated = max(actualAge, actualAge + Int(totalBoost.rounded()))

    return HearingAgeEstimate(
        estimatedAge: estimated,
        actualAge: actualAge,
        preAppBoost: preAppBoost,
        recentBoost: recentBoost
    )
}

struct HealthView: View {
    @State private var hk = HearingHealthManager()
    @Query private var manualSessions: [ManualSession]
    
    @AppStorage("birthDate") private var birthDateInterval: Double = Date().timeIntervalSince1970
    @AppStorage("yearsWearing") private var yearsWearing: Int = 0
    @AppStorage("hoursPerDay") private var hoursPerDay: Int = 0
    @AppStorage("volumeLevel") private var volumeLevel: String = "Medium"

    @State private var weeklyData: [DailyDose] = []
    @State private var isLoading = true
    
    private var actualAge: Int {
        let birthDate = Date(timeIntervalSince1970: birthDateInterval)
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }

    private var lastSessionDate: Date? {
        let allSessions: [Date] = hk.sessions.map(\.endDate) +
            manualSessions.map(\.endTime)
        return allSessions.max()
    }

    private var hoursSinceLastSession: Double {
        guard let last = lastSessionDate else { return 999 }
        return Date().timeIntervalSince(last) / 3600
    }

    private var recoveryPercent: Double {
        ttsRecoveryPercent(hoursSinceLastSession: hoursSinceLastSession)
    }

    private var hoursToFullRecovery: Double {
        hoursUntilFullyRecovered(currentRecoveryPercent: recoveryPercent)
    }

    private var isFullyRecovered: Bool { recoveryPercent >= 95 }

    private var weeklyAvgDose: Double {
        guard !weeklyData.isEmpty else { return 0 }
        return weeklyData.map(\.value).reduce(0, +) / Double(weeklyData.count)
    }

    private var hearingAge: HearingAgeEstimate {
        estimateHearingAge(
            actualAge: actualAge, // Now dynamic from birthDate
            yearsWearing: yearsWearing,
            hoursPerDay: hoursPerDay,
            volumeLevel: volumeLevel,
            weeklyAvgDose: weeklyAvgDose
        )
    }

    private var weeklyListenedHours: Double {
        let hkHours = hk.sessions.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } / 3600
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())!.start
        let manualHours = manualSessions
            .filter { $0.startTime >= startOfWeek }
            .reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) } / 3600
        return hkHours + manualHours
    }

    private var monthlyListenedHours: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())!.start
        let manualHours = manualSessions
            .filter { $0.startTime >= startOfMonth }
            .reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) } / 3600
        return manualHours + (weeklyListenedHours * 4.3)
    }

    private var safeDaysStreak: Int {
        guard !weeklyData.isEmpty else { return 0 }
        var streak = 0
        for day in weeklyData.reversed() {
            if day.value < 100 { streak += 1 } else { break }
        }
        return streak
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Hearing Age")
                    .font(.headline)

                HearingAgeCard(estimate: hearingAge, volumeLevel: volumeLevel, yearsWearing: yearsWearing)

                Text("Ear Recovery")
                    .font(.headline)

                EarRecoveryCard(
                    recoveryPercent: recoveryPercent,
                    hoursToFullRecovery: hoursToFullRecovery,
                    isFullyRecovered: isFullyRecovered
                )

                Text("Cumulative Stats")
                    .font(.headline)

                VStack(spacing: 0) {
                    CumulativeStatRow(label: "this week", value: String(format: "%.1f hrs", weeklyListenedHours))
                    Divider().background(Color.gray.opacity(0.2))
                    CumulativeStatRow(label: "this month", value: String(format: "%.1f hrs", monthlyListenedHours))
                    Divider().background(Color.gray.opacity(0.2))
                    CumulativeStatRow(label: "safe days streak", value: "\(safeDaysStreak) days")
                }
                .background(Color.white.opacity(0.07))
                .cornerRadius(12)
            }
            .padding()
        }
        .task {
            try? await hk.requestAuthorization()
            await hk.loadToday()
            await loadWeeklyData()
        }
    }

    private func loadWeeklyData() async {
        do {
            weeklyData = try await hk.fetchDailyAverages(pastDays: 7)
        } catch {
            print("[HealthView] weekly data error:", error)
        }
        isLoading = false
    }
}

struct HearingAgeCard: View {
    let estimate: HearingAgeEstimate
    let volumeLevel: String
    let yearsWearing: Int

    var ageColor: Color {
        let diff = estimate.difference
        if diff >= 5 { return .red }
        if diff >= 2 { return .orange }
        return .mint
    }
    
    private var breakdownText: String {
        let preRounded = Int(estimate.preAppBoost.rounded())
        let recentRounded = Int(estimate.recentBoost.rounded())
        var parts: [String] = []
        if preRounded > 0 {
            parts.append("\(preRounded) yr\(preRounded == 1 ? "" : "s") from \(yearsWearing)-yr history at \(volumeLevel.lowercased()) volume")
        }
        if recentRounded > 0 {
            parts.append("\(recentRounded) yr\(recentRounded == 1 ? "" : "s") from recent listening")
        }
        return parts.isEmpty ? "your listening habits look safe" : parts.joined(separator: " + ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(estimate.estimatedAge)")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(ageColor)
                    Text("estimated hearing age")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()

                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(estimate.actualAge)")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    Text("actual age")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 6)
            }

            Divider().background(Color.gray.opacity(0.25))

            Text(breakdownText)
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)

            Text("Based on your listening history + HealthKit data using ISO 1999 — not a medical diagnosis")
                .font(.caption2)
                .foregroundColor(Color.gray.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
    }
}

struct EarRecoveryCard: View {
    let recoveryPercent: Double
    let hoursToFullRecovery: Double
    let isFullyRecovered: Bool

    private var recoveryColor: Color {
        if recoveryPercent >= 95 { return .mint }
        if recoveryPercent >= 60 { return .mint }
        return .orange
    }

    private var recoveryLabel: String {"recovered since last session"
    }

    private var subtitleText: String {
        if isFullyRecovered { return "your hearing has fully recovered" }
        let hrs = hoursToFullRecovery
        if hrs < 1 { return "fully recovered in < 1 hr" }
        return String(format: "fully recovered in ~%.0f hrs", ceil(hrs))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(recoveryLabel)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%.0f%%", recoveryPercent))
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(recoveryColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(recoveryColor)
                        .frame(width: geo.size.width * CGFloat(min(recoveryPercent / 100, 1.0)), height: 10)
                        .animation(.easeOut(duration: 1.0), value: recoveryPercent)
                }
            }
            .frame(height: 10)

            Text(subtitleText)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
    }
}

struct CumulativeStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
