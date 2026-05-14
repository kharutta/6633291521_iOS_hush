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
    avgDose: Double
) -> HearingAgeEstimate {
    let dB = volumeLevelToDecibels(volumeLevel)
    let dailyDosePercent = (Double(hoursPerDay) / allowedHours(dB: dB)) * 100.0
    let excessDailyDose = max(0, dailyDosePercent - 50.0)
    let preAppBoost = (excessDailyDose / 100.0) * Double(yearsWearing) * 0.05 * 100

    let recentExcess = max(0, avgDose - 50.0)
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
    guard todayDosePercent > 0 else { return 100.0 }
  
    let halfLifeHours: Double = 3.0
    let remainingDose = todayDosePercent * pow(0.5, hoursSinceLastSession / halfLifeHours)
    let recoveryProgress = ((todayDosePercent - remainingDose) / todayDosePercent) * 100.0
    
    return min(100.0, max(0.0, recoveryProgress))
}

func hoursUntilFullyRecovered(hoursSinceLastSession: Double, todayDosePercent: Double) -> Double {
    guard todayDosePercent > 1.0 else { return 0.0 }
    
    let halfLifeHours: Double = 3.0
    let safeThresholdPercent: Double = 1.0
    
    let totalHoursNeeded = halfLifeHours * (log(safeThresholdPercent / todayDosePercent) / log(0.5))
    
    let remainingTime = totalHoursNeeded - hoursSinceLastSession
    
    return max(0.0, remainingTime)
}
