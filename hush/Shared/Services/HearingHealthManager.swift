import HealthKit
import Observation

@MainActor
@Observable
class HearingHealthManager {
    var sessions: [HKQuantitySample] = []
    var totalDose: Double = 0
    var avgDB: Double = 0

    private let store = HKHealthStore()

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
        print("[HK] Authorization status: \(status.rawValue)")
    }

    func loadToday() async {
        do {
            let fetched = try await fetchTodaySessions()
            self.sessions = fetched
            self.totalDose = totalDosePercent(samples: fetched)
            self.avgDB = averageDB(samples: fetched)
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
