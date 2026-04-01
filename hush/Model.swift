import SwiftUI

struct DailyDose: Identifiable {
    let id = UUID()
    let day: String
    let value: Double
    
    var color: Color {
        if value > 85 { return .red }
        if value > 60 { return .orange }
        return .mint
    }
}

struct InsightData: Identifiable {
    let id = UUID()
    let color: Color
    let text: String
}
