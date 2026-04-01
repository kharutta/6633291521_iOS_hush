import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            OnboardingView()
                .tabItem { Label("OnBoard", systemImage: "house.fill") }
            
            TodayView()
                .tabItem { Label("today", systemImage: "earbuds") }
            
            HistoryView()
                .tabItem { Label("history", systemImage: "chart.bar.fill") }
            
//            HealthView()
//                .tabItem { Label("health", systemImage: "heart.fill") }
//            
//            ManualLogView()
//                .tabItem { Label("log", systemImage: "plus.circle.fill") }
//            
//            TestView()
//                .tabItem { Label("test", systemImage: "heart.text.clipboard.fill") }
        }
        .accentColor(.blue)
        .preferredColorScheme(.dark)
    }
}
