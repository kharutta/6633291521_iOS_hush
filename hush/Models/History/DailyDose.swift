import SwiftUI

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
