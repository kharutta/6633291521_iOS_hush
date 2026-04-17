import Foundation

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
