import SwiftUI
import SwiftData

struct ManualLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDevice: String = "AirPods Pro"
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(60 * 60)
    @State private var volume: Double = 70 // dB
    @State private var selectedActivity: String = "music"
    @State private var showSuccess: Bool = false

    private let devices = ["AirPods Pro", "AirPods Max", "EarPods", "Headphone", "Speakers", "Other"]
    private let activities = ["music", "podcast", "call", "video", "gaming", "work", "Other"]

    private var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    private var volumeDisplay: String {
        "~\(Int(volume)) dB"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    Text("Log Session")
                        .font(.largeTitle)
                        .bold()

                    VStack(alignment: .leading) {
                        Text("device")
                            .foregroundColor(.gray)
                            .font(.caption)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(devices, id: \.self) { device in
                                    CapsuleButton(
                                        title: device,
                                        isSelected: selectedDevice == device
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDevice = device
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("duration")
                            .foregroundColor(.gray)
                            .font(.caption)
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("start")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .accentColor(.mint)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)

                            VStack(alignment: .leading) {
                                Text("end")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .accentColor(.mint)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("volume")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Spacer()
                            Text(volumeDisplay)
                                .bold()
                                .foregroundColor(volumeColor)
                        }
                        Slider(value: $volume, in: 40...120, step: 1)
                            .accentColor(volumeColor)
                        HStack {
                            Text("40 dB")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("120 dB")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                    VStack(alignment: .leading) {
                        Text("activity")
                            .foregroundColor(.gray)
                            .font(.caption)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(activities, id: \.self) { activity in
                                    CapsuleButton(
                                        title: activity,
                                        isSelected: selectedActivity == activity
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedActivity = activity
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("summary")
                            .foregroundColor(.gray)
                            .font(.caption)

                        HStack {
                            Image(systemName: deviceIcon)
                                .foregroundColor(.mint)
                            Text(selectedDevice)
                            Spacer()
                            Text("\(durationMinutes) min")
                                .bold()
                        }

                        HStack {
                            Image(systemName: activityIcon)
                                .foregroundColor(.mint)
                            Text(selectedActivity.capitalized)
                            Spacer()
                            Text(volumeDisplay)
                                .bold()
                                .foregroundColor(volumeColor)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    
                    VStack{
                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.mint)
                                Text("Session added!")
                                    .foregroundColor(.mint)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .cornerRadius(12)
                        }
                        else {
                            Button(action: addSession) {
                                Text("add session")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.mint)
                                    .foregroundColor(.black)
                                    .cornerRadius(15)
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            selectedDevice = "AirPods Pro"
            selectedActivity = "music"
            startTime = Date()
            endTime = Date().addingTimeInterval(60 * 60)
            volume = 70
            showSuccess = false
        }
    }

    private var volumeColor: Color {
        switch volume {
        case ..<70: return .green
        case 70..<85: return .yellow
        case 85..<100: return .orange
        default: return .red
        }
    }

    private var deviceIcon: String {
        switch selectedDevice {
        case "AirPods Pro": return "airpods.pro"
        case "AirPods Max": return "beats.headphones"
        case "EarPods": return "earpods"
        case "Headphone": return "headphones"
        case "Speakers": return "speaker.wave.2"
        default: return "questionmark.circle"
        }
    }

    private var activityIcon: String {
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

    private func addSession() {
        guard durationMinutes > 0 else { return }

        let session = ManualSession(
            device: selectedDevice,
            startTime: startTime,
            endTime: endTime,
            volume: volume,
            activity: selectedActivity
        )

        modelContext.insert(session)

        withAnimation {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSuccess = false
                selectedDevice = "AirPods Pro"
                selectedActivity = "music"
                startTime = Date()
                endTime = Date().addingTimeInterval(60 * 60)
                volume = 70
            }
        }
    }
}
