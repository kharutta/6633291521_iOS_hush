import AVFoundation
import Observation
import SwiftUI
import Combine

@Observable
class HearingTestManager {
    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    
    var isPlaying = false
    var testResults: [Int: Float] = [:]

    init() {
        let mainMixer = engine.mainMixerNode
        engine.attach(playerNode)
        engine.connect(playerNode, to: mainMixer, format: nil)
        try? engine.start()
    }
    
    func stop() {
        playerNode.stop()
        self.isPlaying = false
    }
    
    func playTone(frequency: Double, volume: Float) {
        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let duration = 0.8
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: engine.mainMixerNode.outputFormat(forBus: 0), frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        let channels = Int(buffer.format.channelCount)
        for frame in 0..<Int(frameCount) {
            let val = sinf(Float(2.0 * .pi * frequency * Double(frame) / sampleRate))
            for channel in 0..<channels {
                buffer.floatChannelData?[channel][frame] = val * volume
            }
        }
        
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts) {
            Task { @MainActor in self.isPlaying = false }
        }
        playerNode.play()
        self.isPlaying = true
    }
}

struct TestView: View {
    @State private var testManager = HearingTestManager()
    @State private var testFrequencies = [500, 1000, 2000, 4000, 8000]
    @State private var currentIndex = 0
    @State private var dbLevel: Float = 0.01
    
    @State private var isTesting = false
    @State private var showResult = false
    
    let timer = Timer.publish(every: 1.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if showResult {
                ResultSummaryView(results: testManager.testResults, frequencies: testFrequencies) {
                    resetTest()
                }
            } else if !isTesting {
                StartScreenView { isTesting = true }
            } else {
                TestingScreenView(
                    frequency: testFrequencies[currentIndex],
                    decibels: dbLevel,
                    isPlaying: testManager.isPlaying,
                    onHear: recordResult
                )
            }
        }
        .onReceive(timer) { _ in
            guard isTesting && !testManager.isPlaying else { return }
            testManager.playTone(frequency: Double(testFrequencies[currentIndex]), volume: dbLevel)
            dbLevel += 0.01
        }
        .onDisappear {
            stopAndResetAll()
        }
    }

    func recordResult() {
        testManager.testResults[testFrequencies[currentIndex]] = dbLevel
        
        if currentIndex < testFrequencies.count - 1 {
            currentIndex += 1
            dbLevel = 0.01
        } else {
            isTesting = false
            showResult = true
        }
    }

    private func stopAndResetAll() {
        testManager.stop()
        isTesting = false
        currentIndex = 0
        dbLevel = 0.005
    }
    
    func resetTest() {
        testManager.testResults = [:]
        currentIndex = 0
        dbLevel = 0.01
        showResult = false
        isTesting = false
    }
}

struct StartScreenView: View {
    var onStart: () -> Void
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "ear.and.waveform")
                .font(.system(size: 80))
                .foregroundColor(.mint)
            Text("Hearing Test")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            Text("We will play tones at different frequencies. Tap the button as soon as you hear the faint sound.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            Button(action: onStart) {
                Text("Start Test")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mint)
                    .foregroundColor(.black)
                    .cornerRadius(15)
            }.padding(.horizontal, 40)
        }
    }
}

struct TestingScreenView: View {
    let frequency: Int
    let decibels: Float
    let isPlaying: Bool
    var onHear: () -> Void
    
    var body: some View {
        VStack(spacing: 50) {
            VStack(spacing: 20){
                Text("\(frequency) Hz")
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("\(String(format: "%.2f", decibels)) dB")
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            ZStack {
                Circle()
                    .stroke(isPlaying ? Color.mint : Color.white.opacity(0.1), lineWidth: 4)
                    .scaleEffect(isPlaying ? 1.4 : 1.0)
                    .opacity(isPlaying ? 0 : 1)
                    .animation(isPlaying ? .easeOut(duration: 1.0).repeatForever(autoreverses: false) : .default, value: isPlaying)
                    .frame(width: 180, height: 180)

                Button(action: onHear) {
                    Text("I Hear It")
                        .font(.headline)
                        .foregroundColor(isPlaying ? .black : .mint)
                        .padding(50)
                        .background(isPlaying ? Color.mint : Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(!isPlaying)
            }
            Text("Listen carefully for the tone...")
                .foregroundColor(.gray)
        }
    }
}

struct ResultSummaryView: View {
    let results: [Int: Float]
    let frequencies: [Int]
    var onReset: () -> Void
    
    private var averageDB: Float {
        let coreFreqs = [500, 1000, 2000, 4000]
        let sum = coreFreqs.reduce(0) { $0 + (results[$1] ?? 0) }
        return (sum / Float(coreFreqs.count)) * 100
    }
    
    private func interpretPTA(_ avg: Float) -> (status: String, info: String, color: Color) {
        switch avg {
        case ..<16:
            return ("Excellent (Normal)", "You can hear faint whispers and rustling leaves clearly.", .mint)
        case 16...25:
            return ("Slightly Impaired", "You may have slight difficulty in very noisy environments.", .green)
        case 26...40:
            return ("Mild Loss", "Quiet speech or distant sounds may be hard to hear.", .orange)
        case 41...55:
            return ("Moderate Loss", "Normal conversation is difficult. people may need to speak louder.", .red)
        case 56...70:
            return ("Moderately-Severe Loss", "Challenges with most everyday speech.", .red)
        case 71...90:
            return ("Severe Loss", "Only very loud sounds are audible.", .purple)
        default:
            return ("Profound Loss", "Minimal or no usable hearing.", .purple)
        }
    }

    var body: some View {
        let interpretation = interpretPTA(averageDB)
        
        ScrollView {
            VStack(spacing: 25) {
                Text("Test Results")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.top, 40)

                VStack(spacing: 15) {
                    Text("Pure Tone Average (PTA)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("\(String(format: "%.1f", averageDB)) dB HL")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(interpretation.color)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    VStack(spacing: 8) {
                        Text(interpretation.status)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(interpretation.info)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 5)
                }
                .padding(25)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(interpretation.color.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 15) {
                    Text("Frequency Details")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                    
                    ForEach(frequencies, id: \.self) { freq in
                        let val = (results[freq] ?? 0) * 100
                        HStack {
                            Text("\(freq) Hz")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(String(format: "%.1f", val)) dB")
                                .bold()
                                .foregroundColor(val > 25 ? .orange : .mint)
                        }
                        .padding()
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Button(action: onReset) {
                    Text("Restart Test")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.mint)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Text("Note: This test is a preliminary assessment and cannot replace a professional medical diagnosis.")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
            }
        }
    }
}
