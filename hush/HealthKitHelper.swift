import HealthKit

@MainActor
@Observable
class HearingHealthManager {
    var sessions: [HKQuantitySample] = []
    var totalDose: Double = 0
    var avgDB: Double = 0

    private let store = HKHealthStore()

    // Permission
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("[HK] HealthKit not available on this device")
            return
        }
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.headphoneAudioExposure)
        ]
        print("[HK] Requesting authorization...")
        try await store.requestAuthorization(toShare: [], read: readTypes)

        let status = store.authorizationStatus(for: HKQuantityType(.headphoneAudioExposure))
        print("[HK] Authorization status: \(status.rawValue)") // 0=notDetermined 1=denied 2=authorized
    }

    func loadToday() async {
        do {
            let fetched = try await fetchTodaySessions()
            print("[HK] Today sessions count: \(fetched.count)")
            for s in fetched {
                let dB = s.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel())
                let dur = s.endDate.timeIntervalSince(s.startDate)
                print("[HK]   \(s.startDate) → \(s.endDate) | \(Int(dB)) dB | \(Int(dur))s | source: \(s.sourceRevision.source.name)")
            }
            self.sessions = fetched
            self.totalDose = totalDosePercent(samples: fetched)
            self.avgDB = averageDB(samples: fetched)
            print("[HK] totalDose=\(totalDose) avgDB=\(avgDB)")
        } catch {
            print("[HK] loadToday error: \(error)")
        }
    }

    private func fetchTodaySessions() async throws -> [HKQuantitySample] {
        let type = HKQuantityType(.headphoneAudioExposure)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
            }
            store.execute(query)
        }
    }

    func fetchDailyAverages(pastDays: Int = 7) async throws -> [DailyDose] {
        let type = HKQuantityType(.headphoneAudioExposure)
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -pastDays, to: endDate)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, result, error in
                if let error { continuation.resume(throwing: error); return }
                let typed = (result as? [HKQuantitySample]) ?? []
                continuation.resume(returning: typed)
            }
            store.execute(query)
        }

        for s in samples {
            let dB = s.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel())
            let dur = s.endDate.timeIntervalSince(s.startDate)
            print("[HK]   \(s.startDate) | \(Int(dB)) dB | \(Int(dur))s")
        }

        var byDay: [Date: [HKQuantitySample]] = [:]
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            byDay[day, default: []].append(sample)
        }

        var result: [DailyDose] = []
        for offset in (0..<pastDays).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: endDate)) else { continue }
            let daySamples = byDay[day] ?? []
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]

            let dose = totalDosePercent(samples: daySamples)
            let avg = averageDB(samples: daySamples)
            
            result.append(DailyDose(date: day, day: dayName, value: dose, avgDB: avg))
        }

        return result
    }
}

// NIOSH Formula Helpers

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
