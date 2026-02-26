import SwiftUI

struct HealthReportView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @ObservedObject var healthKitManager: HealthKitManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Health Score Ring
                healthScoreSection

                // Health Indicators
                healthIndicatorsSection

                // Information Section
                informationSection

                // Vital Signs
                vitalSignsSection
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Health Score
    private var healthScoreSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: CGFloat(healthKitManager.healthScore) / 100)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)], startPoint: .leading,
                            endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: healthKitManager.healthScore)

                VStack(spacing: 2) {
                    Text("\(healthKitManager.healthScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Health Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Health Report – \(healthKitManager.healthStatus)")
                .font(.title3.bold())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
    }

    // MARK: - Health Indicators
    private var healthIndicatorsSection: some View {
        HStack(spacing: 0) {
            HealthIndicatorItem(
                icon: "heart.fill",
                iconColor: .red,
                label: healthKitManager.heartRateStatus
            )

            HealthIndicatorItem(
                icon: "figure.walk",
                iconColor: .green,
                label: healthKitManager.stepCount > 8000 ? "Active" : "Move More"
            )

            HealthIndicatorItem(
                icon: "drop.fill",
                iconColor: .red,
                label: healthKitManager.bpStatus
            )

            HealthIndicatorItem(
                icon: "stethoscope",
                iconColor: .blue,
                label: healthKitManager.healthStatus
            )
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
    }

    // MARK: - Information Section
    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Blood Pressure - \(healthKitManager.bpStatus)")
                        .font(.subheadline.bold())

                    Text(
                        "Please keep track of your BP everyday (20 minutes after waking up) and consult a doctor for better understanding of your blood pressure status."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
    }

    // MARK: - Vital Signs Section
    private var vitalSignsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vital Signs")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: HistoryView(emergencyManager: emergencyManager)) {
                    Text("View History >")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 0) {
                VitalSignItem(
                    icon: "thermometer", label: "BT",
                    value: healthKitManager.bodyTempText)
                VitalSignItem(
                    icon: "drop.fill", label: "BP",
                    value: healthKitManager.bloodPressureText)
                VitalSignItem(
                    icon: "lungs.fill", label: "RR",
                    value: healthKitManager.respiratoryRateText)
                VitalSignItem(
                    icon: "waveform.path.ecg", label: "HR",
                    value: healthKitManager.heartRateText)
            }

            Text(
                healthKitManager.heartRate > 0
                    ? "Connected to Apple Watch ✓" : "Connect Apple Watch for live data"
            )
            .font(.caption)
            .foregroundColor(healthKitManager.heartRate > 0 ? .green : .secondary)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
}

// MARK: - Health Indicator Item
struct HealthIndicatorItem: View {
    let icon: String
    let iconColor: Color
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Vital Sign Item
struct VitalSignItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.red)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        HealthReportView(emergencyManager: EmergencyManager(), healthKitManager: HealthKitManager())
    }
}
