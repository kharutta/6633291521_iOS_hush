import SwiftUI
import Combine

struct TestView: View {
    @State private var testManager = HearingTestManager()
    @State private var testFrequencies = [500, 1000, 2000, 4000]
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
