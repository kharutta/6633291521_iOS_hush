import HealthKit

func allowedHours(dB: Double) -> Double {
    return 8.0 / pow(2.0, (dB - 85.0) / 3.0)
}

func sampleDosePercent(dB: Double, durationSeconds: Double) -> Double {
    return (durationSeconds / 3600) / allowedHours(dB: dB) * 100
}

func totalDosePercent(samples: [HKQuantitySample]) -> Double {
    let unit = HKUnit.decibelAWeightedSoundPressureLevel()
    return samples.reduce(0.0) { total, sample in
        let dB = sample.quantity.doubleValue(for: unit)
        let duration = sample.endDate.timeIntervalSince(sample.startDate)
        return total + sampleDosePercent(dB: dB, durationSeconds: duration)
    }
}

func averageDB(samples: [HKQuantitySample]) -> Double {
    guard !samples.isEmpty else { return 0 }
    let unit = HKUnit.decibelAWeightedSoundPressureLevel()
    return samples.map { $0.quantity.doubleValue(for: unit) }.reduce(0, +) / Double(samples.count)
}

func safeUntil(currentDose: Double, avgDB: Double) -> Date {
    let remainingDose = max(0, 100 - currentDose)
    let remainingHours = (remainingDose / 100) * allowedHours(dB: avgDB)
    let calculatedDate = Date().addingTimeInterval(remainingHours * 3600)

    let calendar = Calendar.current
    let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? calculatedDate

    return min(calculatedDate, endOfToday)
}

func decibelToDosePercent(dB: Double, hours: Double) -> Double {
    return (hours / allowedHours(dB: dB)) * 100
}
