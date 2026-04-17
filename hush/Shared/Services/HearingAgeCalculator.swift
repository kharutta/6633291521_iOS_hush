import Foundation
 
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

func ttsRecoveryPercent(hoursSinceLastSession: Double, todayDosePercent: Double) -> Double {
    let ttsHalfLife: Double = 16.0
    let ttsThreshold: Double = 0.05
    
    let severity = todayDosePercent / 100.0
    guard severity > ttsThreshold else { return 100.0 }
    guard hoursSinceLastSession >= 0 else { return 0 }
    let remaining = severity * pow(0.5, hoursSinceLastSession / ttsHalfLife)
    let pct = (1.0 - remaining / severity) * 100.0
    return min(100.0, max(0.0, pct))
}

func hoursUntilFullyRecovered(hoursSinceLastSession: Double, todayDosePercent: Double) -> Double {
    let ttsHalfLife: Double = 16.0
    let ttsThreshold: Double = 0.05
    
    let severity = todayDosePercent / 100.0
    guard severity > ttsThreshold else { return 0 }
    let totalHoursNeeded = ttsHalfLife * log2(severity / ttsThreshold)
    return max(0, totalHoursNeeded - hoursSinceLastSession)
}
