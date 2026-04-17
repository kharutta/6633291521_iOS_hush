import SwiftUI
import HealthKit

struct UnifiedSession: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let dB: Double
    let source: String
    let activity: String?
    let isManual: Bool

    var durationSeconds: Double {
        endDate.timeIntervalSince(startDate)
    }

    var dosePercent: Double {
        sampleDosePercent(dB: dB, durationSeconds: durationSeconds)
    }

    init(from sample: HKQuantitySample) {
        self.id = sample.uuid
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.dB = sample.quantity.doubleValue(for: HKUnit.decibelAWeightedSoundPressureLevel())
        self.source = sample.sourceRevision.source.name
        self.activity = nil
        self.isManual = false
    }

    init(from manual: ManualSession) {
        self.id = UUID()
        self.startDate = manual.startTime
        self.endDate = manual.endTime
        self.dB = manual.volume
        self.source = manual.device
        self.activity = manual.activity
        self.isManual = true
    }
}
