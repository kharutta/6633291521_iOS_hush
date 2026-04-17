import Foundation
import SwiftData

@Model
final class ManualSession {
    var device: String
    var startTime: Date
    var endTime: Date
    var volume: Double
    var activity: String
    var timestamp: Date

    init(device: String, startTime: Date, endTime: Date, volume: Double, activity: String) {
        self.device = device
        self.startTime = startTime
        self.endTime = endTime
        self.volume = volume
        self.activity = activity
        self.timestamp = Date()
    }

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
}
