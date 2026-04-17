import SwiftUI
import SwiftData

@MainActor
@Observable
class ManualLogViewModel {
    var selectedDevice: String = "AirPods Pro"
    var startTime: Date = Date()
    var endTime: Date = Date().addingTimeInterval(60 * 60)
    var volume: Double = 70
    var selectedActivity: String = "music"
    var showSuccess: Bool = false

    let devices = ["AirPods Pro", "AirPods Max", "EarPods", "Headphone", "Speakers", "Other"]
    let activities = ["music", "podcast", "call", "video", "gaming", "work", "Other"]

    var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    var volumeDisplay: String {
        "~\(Int(volume)) dB"
    }

    var volumeColor: Color {
        switch volume {
        case ..<70: return .green
        case 70..<85: return .yellow
        case 85..<100: return .orange
        default: return .red
        }
    }

    var deviceIcon: String {
        switch selectedDevice {
        case "AirPods Pro": return "airpods.pro"
        case "AirPods Max": return "beats.headphones"
        case "EarPods": return "earpods"
        case "Headphone": return "headphones"
        case "Speakers": return "speaker.wave.2"
        default: return "questionmark.circle"
        }
    }

    var activityIcon: String {
        switch selectedActivity {
        case "music": return "music.note"
        case "podcast": return "mic"
        case "call": return "phone"
        case "video": return "play.rectangle"
        case "gaming": return "gamecontroller"
        case "work": return "briefcase"
        default: return "star"
        }
    }

    func addSession(to context: ModelContext) {
        guard durationMinutes > 0 else { return }

        let session = ManualSession(
            device: selectedDevice,
            startTime: startTime,
            endTime: endTime,
            volume: volume,
            activity: selectedActivity
        )

        context.insert(session)

        withAnimation {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.resetForm()
            }
        }
    }

    func resetForm() {
        selectedDevice = "AirPods Pro"
        selectedActivity = "music"
        startTime = Date()
        endTime = Date().addingTimeInterval(60 * 60)
        volume = 70
        showSuccess = false
    }
}
