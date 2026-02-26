import Foundation
import SwiftUI

final class HealthKitManager: ObservableObject {
    @Published var heartRate: Double = 72
    @Published var bodyTemperature: Double = 36.6
    @Published var respiratoryRate: Double = 16
    @Published var systolicBP: Double = 120
    @Published var diastolicBP: Double = 80
    @Published var stepCount: Double = 0
    @Published var isAuthorized = false
    @Published var lastUpdated: Date? = Date()
    @Published var watchConnected = false

    var heartRateText: String {
        "\(Int(heartRate)) Bpm"
    }

    var bodyTempText: String {
        String(format: "%.1f°C", bodyTemperature)
    }

    var respiratoryRateText: String {
        "\(Int(respiratoryRate)) Bpm"
    }

    var bloodPressureText: String {
        "\(Int(systolicBP))/\(Int(diastolicBP))"
    }

    var heartRateStatus: String {
        if heartRate < 60 { return "Low" }
        if heartRate > 100 { return "High" }
        return "Normal"
    }

    var bpStatus: String {
        if systolicBP > 140 || diastolicBP > 90 { return "High" }
        if systolicBP < 90 || diastolicBP < 60 { return "Low" }
        return "Normal"
    }

    var healthScore: Int {
        var score = 50
        if heartRate >= 60 && heartRate <= 100 {
            score += 15
        } else if heartRate >= 50 && heartRate <= 110 {
            score += 8
        }
        if systolicBP >= 90 && systolicBP <= 130 && diastolicBP >= 60 && diastolicBP <= 85 {
            score += 15
        } else if systolicBP >= 85 && systolicBP <= 140 {
            score += 8
        }
        if bodyTemperature >= 36.1 && bodyTemperature <= 37.2 {
            score += 10
        } else if bodyTemperature >= 35.5 && bodyTemperature <= 38.0 {
            score += 5
        }
        if stepCount > 8000 {
            score += 10
        } else if stepCount > 5000 {
            score += 7
        } else if stepCount > 2000 {
            score += 4
        }
        return min(score, 100)
    }

    var healthStatus: String {
        let s = healthScore
        if s >= 80 { return "Good" }
        if s >= 60 { return "Average" }
        if s >= 40 { return "Below Average" }
        return "Needs Attention"
    }

    func requestAuthorization() {
        isAuthorized = true
    }

    func fetchAllData() {
        lastUpdated = Date()
    }

    func startObserving() {
        // Placeholder for when HealthKit is available on a real device
    }
}
