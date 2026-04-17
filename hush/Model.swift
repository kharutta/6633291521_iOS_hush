import SwiftUI
import HealthKit

struct DailyDose: Identifiable {
    let id = UUID()
    let date: Date
    let day: String
    let value: Double
    let avgDB: Double

    var color: Color {
        if value > 85 { return .red }
        if value > 60 { return .orange }
        return .mint
    }
}

struct InsightData: Identifiable {
    let id = UUID()
    let color: Color
    let title: String
    let subtitle: String
}

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
