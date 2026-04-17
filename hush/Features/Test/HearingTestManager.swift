import AVFoundation
import Observation

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
