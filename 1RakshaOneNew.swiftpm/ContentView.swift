import SwiftUI

struct ContentView: View {
    @StateObject private var emergencyManager = EmergencyManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Profile Card
                    ProfileCardView(
                        emergencyManager: emergencyManager, locationManager: locationManager)

                    // Tab Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            TabLabel(title: "SOS", isSelected: selectedTab == 0) { selectedTab = 0 }
                            TabLabel(title: "Health Summary", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                            TabLabel(title: "Health Info", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                            TabLabel(title: "Vital Signs", isSelected: selectedTab == 3) {
                                selectedTab = 3
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    .padding(.top, 4)

                    // Tab Content
                    TabView(selection: $selectedTab) {
                        // Tab 0: SOS Alert
                        SOSAlertView(
                            emergencyManager: emergencyManager, locationManager: locationManager
                        )
                        .tag(0)

                        // Tab 1: Home/Health Summary
                        HomeTabView(
                            emergencyManager: emergencyManager, locationManager: locationManager
                        )
                        .tag(1)

                        // Tab 2: Health Report
                        HealthReportView(
                            emergencyManager: emergencyManager, healthKitManager: healthKitManager
                        )
                        .tag(2)

                        // Tab 3: Vital Signs
                        VitalSignsTabView(
                            emergencyManager: emergencyManager, healthKitManager: healthKitManager
                        )
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            locationManager.requestPermission()
            healthKitManager.requestAuthorization()
        }
        .onShake {
            if emergencyManager.shakeToSOSEnabled {
                emergencyManager.startSOSCountdown(location: locationManager.currentLocation)
                selectedTab = 3
            }
        }
    }
}

// MARK: - Profile Card
struct ProfileCardView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @ObservedObject var locationManager: LocationManager
    @State private var showCallSheet = false
    @State private var showEditProfile = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(emergencyManager.userProfile.name)
                            .font(.headline.bold())
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text(
                            "\(emergencyManager.userProfile.gender), \(emergencyManager.userProfile.age) years"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Blood Type Badge
                Text(emergencyManager.userProfile.bloodType)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.red)
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showEditProfile = true
            }

            // Action Buttons
            HStack(spacing: 12) {
                // Call - pick contact to call
                Button(action: {
                    if emergencyManager.emergencyContacts.count == 1 {
                        callContact(emergencyManager.emergencyContacts[0])
                    } else if !emergencyManager.emergencyContacts.isEmpty {
                        showCallSheet = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("Call")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .confirmationDialog(
                    "Call Emergency Contact", isPresented: $showCallSheet, titleVisibility: .visible
                ) {
                    ForEach(emergencyManager.emergencyContacts) { contact in
                        Button("\(contact.name) – \(contact.phoneNumber)") {
                            callContact(contact)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }

                // Chat - opens MessagingView
                NavigationLink(destination: MessagingView()) {
                    HStack(spacing: 6) {
                        Image(systemName: "message.fill")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text("Chat")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }

                // Direction - opens current location in Apple Maps
                Button(action: {
                    if let location = locationManager.currentLocation {
                        let lat = location.coordinate.latitude
                        let lon = location.coordinate.longitude
                        if let url = URL(string: "https://maps.apple.com/?q=\(lat),\(lon)") {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        if let url = URL(string: "https://maps.apple.com/") {
                            UIApplication.shared.open(url)
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text("Direction")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.top, 8)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(emergencyManager: emergencyManager)
        }
    }

    private func callContact(_ contact: EmergencyContact) {
        let cleaned = contact.phoneNumber
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel:\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("Name", text: $emergencyManager.userProfile.name)

                    Stepper(
                        "Age: \(emergencyManager.userProfile.age)",
                        value: $emergencyManager.userProfile.age, in: 1...120)

                    Picker("Gender", selection: $emergencyManager.userProfile.gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                }

                Section(header: Text("Medical Info")) {
                    Picker("Blood Type", selection: $emergencyManager.userProfile.bloodType) {
                        ForEach(["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], id: \.self) {
                            type in
                            Text(type).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        emergencyManager.saveUserProfile()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Profile Action Button
struct ProfileActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Tab Label
struct TabLabel: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .overlay(alignment: .bottom) {
            if isSelected {
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 2)
            }
        }
    }
}

// MARK: - Home Tab (Quick Actions)
struct HomeTabView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {  // Quick Navigation
                VStack(spacing: 12) {
                    NavigationLink(destination: ContactsView(emergencyManager: emergencyManager)) {
                        QuickNavCard(
                            icon: "person.2.fill", title: "Emergency Contacts",
                            subtitle: "\(emergencyManager.emergencyContacts.count) contacts saved",
                            color: .blue)
                    }

                    NavigationLink(destination: HistoryView(emergencyManager: emergencyManager)) {
                        QuickNavCard(
                            icon: "clock.fill", title: "Emergency History",
                            subtitle: "\(emergencyManager.emergencyHistory.count) events logged",
                            color: .orange)
                    }

                    NavigationLink(destination: MessagingView()) {
                        QuickNavCard(
                            icon: "paperplane.fill", title: "Messages",
                            subtitle: "Send alerts and messages", color: .green)
                    }

                    NavigationLink(destination: SettingsView(emergencyManager: emergencyManager)) {
                        QuickNavCard(
                            icon: "gear", title: "Settings",
                            subtitle: "Configure your safety preferences", color: .gray)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Quick Nav Card
struct QuickNavCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - SOS Alert View
struct SOSAlertView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if emergencyManager.sosTimerRunning {
                // Active SOS
                VStack(spacing: 16) {
                    Image(systemName: "asterisk")
                        .font(.system(size: 30))
                        .foregroundColor(.red)

                    Text("Sending Emergency Alert")
                        .font(.title2.bold())

                    Text("SOS Will sent once the timer Off")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Timer Circle
                Button(action: {
                    emergencyManager.stopSOSCountdown()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.red, Color.red.opacity(0.7)],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .shadow(color: .red.opacity(0.4), radius: 20, x: 0, y: 10)

                        VStack(spacing: 4) {
                            Text(String(format: "00 : %02d", emergencyManager.sosCountdown))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Seconds")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

                Text("Tap the timer to stop")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                // Inactive - Show Start Button
                VStack(spacing: 16) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)

                    Text("Emergency SOS")
                        .font(.title2.bold())

                    Text(
                        "Press the button to start a 30-second countdown. SOS alert will be sent when timer reaches zero."
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                }

                Button(action: {
                    emergencyManager.startSOSCountdown(location: locationManager.currentLocation)
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.8)], startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                            .frame(width: 200, height: 200)
                            .shadow(color: .red.opacity(0.4), radius: 20, x: 0, y: 10)

                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)

                            Text("SOS")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            // Recording Button
            Button(action: {
                if emergencyManager.isRecording {
                    emergencyManager.stopAudioRecording()
                } else {
                    emergencyManager.startAudioRecording()
                }
            }) {
                HStack(spacing: 8) {
                    Image(
                        systemName: emergencyManager.isRecording
                            ? "stop.circle.fill" : "mic.circle.fill"
                    )
                    .font(.title3)
                    Text(emergencyManager.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(
                        emergencyManager.isRecording ? Color.gray : Color.red.opacity(0.8))
                )
            }

            if emergencyManager.isRecording {
                Text(emergencyManager.recordingStatus)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Vital Signs Tab
struct VitalSignsTabView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @ObservedObject var healthKitManager: HealthKitManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Watch Connection Status
                HStack {
                    Image(
                        systemName: healthKitManager.watchConnected
                            ? "applewatch.radiowaves.left.and.right" : "applewatch"
                    )
                    .foregroundColor(healthKitManager.watchConnected ? .green : .gray)
                    Text(
                        healthKitManager.watchConnected ? "Apple Watch Connected" : "No Watch Data"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { healthKitManager.fetchAllData() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)

                // Vital Signs Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    VitalDetailCard(
                        icon: "thermometer", title: "Body Temperature",
                        value: healthKitManager.bodyTempText,
                        status: healthKitManager.bodyTemperature > 0 ? "Normal" : "N/A",
                        statusColor: healthKitManager.bodyTemperature > 37.5 ? .red : .green)
                    VitalDetailCard(
                        icon: "drop.fill", title: "Blood Pressure",
                        value: healthKitManager.bloodPressureText,
                        status: healthKitManager.bpStatus,
                        statusColor: healthKitManager.bpStatus == "High" ? .red : .green)
                    VitalDetailCard(
                        icon: "lungs.fill", title: "Respiratory Rate",
                        value: healthKitManager.respiratoryRateText,
                        status: healthKitManager.respiratoryRate > 0 ? "Normal" : "N/A",
                        statusColor: .green)
                    VitalDetailCard(
                        icon: "waveform.path.ecg", title: "Heart Rate",
                        value: healthKitManager.heartRateText,
                        status: healthKitManager.heartRateStatus,
                        statusColor: healthKitManager.heartRateStatus == "High" ? .red : .green)
                }

                // Steps
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Steps Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(healthKitManager.stepCount))")
                            .font(.title2.bold())
                    }
                    Spacer()
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)

                // Health Indicators
                VStack(alignment: .leading, spacing: 12) {
                    Text("Health Indicators")
                        .font(.headline)

                    HealthStatusRow(
                        icon: "heart.fill", title: "Heart Rate",
                        status: healthKitManager.heartRateStatus, color: .red)
                    HealthStatusRow(
                        icon: "drop.fill", title: "Blood Pressure",
                        status: healthKitManager.bpStatus, color: .red)
                    HealthStatusRow(
                        icon: "stethoscope", title: "Overall",
                        status: healthKitManager.healthStatus, color: .blue)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(20)
            }
            .padding()
        }
        .onAppear {
            healthKitManager.fetchAllData()
            healthKitManager.startObserving()
        }
    }
}

// MARK: - Vital Detail Card
struct VitalDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let status: String
    let statusColor: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.red)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.subheadline.bold())

            Text(status)
                .font(.caption2)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.1))
                .cornerRadius(4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Health Status Row
struct HealthStatusRow: View {
    let icon: String
    let title: String
    let status: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(color)
            }

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(status)
                .font(.caption.bold())
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Status Row
struct StatusRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
