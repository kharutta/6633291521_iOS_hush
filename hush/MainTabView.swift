import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 2

    var body: some View {
        TabView(selection: $selectedTab) {
            HistoryView()
                .tabItem { Label("history", systemImage: "chart.bar.fill") }
                .tag(0)

            HealthView()
                .tabItem { Label("health", systemImage: "heart.fill") }
                .tag(1)

            TodayView()
                .tabItem { Label("today", systemImage: "ear.badge.waveform") }
                .tag(2)

            ManualLogView()
                .tabItem { Label("log", systemImage: "plus.circle.fill") }
                .tag(3)

            TestView()
                .tabItem { Label("test", systemImage: "heart.text.clipboard.fill") }
                .tag(4)
        }
        .accentColor(.blue)
        .preferredColorScheme(.dark)
    }
}
