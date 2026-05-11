import SwiftUI

struct HearingAgeEstimate {
    let estimatedAge: Int
    let actualAge: Int
    let preAppBoost: Double
    let recentBoost: Double
    var difference: Int { estimatedAge - actualAge }
}
