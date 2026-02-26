import SwiftUI

struct SettingsView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            // User Profile Section
            Section(header: Text("Profile")) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(emergencyManager.userProfile.name)
                            .font(.headline)
                        Text(
                            "\(emergencyManager.userProfile.gender), \(emergencyManager.userProfile.age) years"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(emergencyManager.userProfile.bloodType)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.red))
                }

                TextField("Name", text: $emergencyManager.userProfile.name)
                    .onChange(of: emergencyManager.userProfile.name) { _ in
                        emergencyManager.saveUserProfile()
                    }

                Stepper(
                    "Age: \(emergencyManager.userProfile.age)",
                    value: $emergencyManager.userProfile.age, in: 1...120
                )
                .onChange(of: emergencyManager.userProfile.age) { _ in
                    emergencyManager.saveUserProfile()
                }

                Picker("Gender", selection: $emergencyManager.userProfile.gender) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
                .onChange(of: emergencyManager.userProfile.gender) { _ in
                    emergencyManager.saveUserProfile()
                }

                Picker("Blood Type", selection: $emergencyManager.userProfile.bloodType) {
                    ForEach(["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], id: \.self) {
                        type in
                        Text(type).tag(type)
                    }
                }
                .onChange(of: emergencyManager.userProfile.bloodType) { _ in
                    emergencyManager.saveUserProfile()
                }
            }

            Section(header: Text("Features")) {
                Toggle("Shake to Trigger SOS", isOn: $emergencyManager.shakeToSOSEnabled)
                    .tint(.red)
            }

            Section(header: Text("Audio Recording")) {
                if emergencyManager.isRecording {
                    Button(action: {
                        emergencyManager.stopAudioRecording()
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                                .foregroundColor(.red)
                            Text("Stop Recording")
                        }
                    }
                } else {
                    Text("Audio recording starts automatically with SOS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Privacy")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("No Login Required")
                    }

                    HStack {
                        Image(systemName: "icloud.slash.fill")
                            .foregroundColor(.green)
                        Text("No Cloud Storage")
                    }

                    HStack {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(.green)
                        Text("No User Tracking")
                    }

                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.green)
                        Text("All Data Stored Locally")
                    }
                }
                .font(.subheadline)
            }

            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Offline Capable")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsView(emergencyManager: EmergencyManager())
    }
}
