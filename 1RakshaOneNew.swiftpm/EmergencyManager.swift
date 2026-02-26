import AVFoundation
import Combine
import CoreLocation
import Foundation
import MessageUI
import UIKit

@MainActor  // Fixes the "Data Race" error by ensuring UI updates happen on the main thread
class EmergencyManager: NSObject, ObservableObject {
    @Published var isSOSActive = false
    @Published var smsStatus = "Ready"
    @Published var recordingStatus = "Not Recording"
    @Published var isRecording = false
    @Published var shakeToSOSEnabled = true
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var emergencyHistory: [EmergencyEvent] = []

    // User Profile
    @Published var userProfile = UserProfile()

    // Health Data
    @Published var healthData = HealthData()

    // SOS Countdown Timer
    @Published var sosCountdown: Int = 30
    @Published var sosTimerRunning = false
    private var sosTimer: Timer?

    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?

    override init() {
        super.init()
        loadContacts()
        loadHistory()
        loadUserProfile()
        setupAudioSession()
    }

    // MARK: - SOS Timer
    func startSOSCountdown(location: CLLocation?) {
        sosCountdown = 30
        sosTimerRunning = true
        isSOSActive = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        sosTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.sosCountdown > 0 {
                    self.sosCountdown -= 1
                } else {
                    self.fireSOSAlert(location: location)
                }
            }
        }
    }

    func stopSOSCountdown() {
        sosTimer?.invalidate()
        sosTimer = nil
        sosTimerRunning = false
        isSOSActive = false
        sosCountdown = 30
    }

    private func fireSOSAlert(location: CLLocation?) {
        sosTimer?.invalidate()
        sosTimer = nil
        sosTimerRunning = false

        // Send SMS
        sendEmergencySMS(location: location)

        // Start audio recording
        startAudioRecording()

        // Log event
        logEmergencyEvent(location: location)

        // Auto-reset after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isSOSActive = false
        }
    }

    // MARK: - SOS Trigger (legacy direct trigger)
    func triggerSOS(location: CLLocation?) {
        isSOSActive = true

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        sendEmergencySMS(location: location)
        startAudioRecording()
        logEmergencyEvent(location: location)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isSOSActive = false
        }
    }

    // MARK: - SMS Handling
    func sendEmergencySMS(location: CLLocation?) {
        guard !emergencyContacts.isEmpty else {
            smsStatus = "No contacts configured"
            return
        }

        let message = createEmergencyMessage(location: location)

        for contact in emergencyContacts {
            if let phoneNumber = contact.phoneNumber.addingPercentEncoding(
                withAllowedCharacters: .urlHostAllowed),
                let messageEncoded = message.addingPercentEncoding(
                    withAllowedCharacters: .urlHostAllowed),
                let smsURL = URL(string: "sms:\(phoneNumber)&body=\(messageEncoded)")
            {

                #if !targetEnvironment(simulator)
                    if UIApplication.shared.canOpenURL(smsURL) {
                        UIApplication.shared.open(smsURL)
                    }
                #endif
            }
        }

        smsStatus = "SMS sent to \(emergencyContacts.count) contact(s)"

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.smsStatus = "Ready"
        }
    }

    private func createEmergencyMessage(location: CLLocation?) -> String {
        var message = "🚨 EMERGENCY ALERT from RakshaOne 🚨\n\n"
        message += "I need immediate help!\n\n"

        if let location = location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            message += "📍 My Location:\n"
            message += "Latitude: \(latitude)\n"
            message += "Longitude: \(longitude)\n"
            // Fixed the URL to a standard Google Maps format
            message += "Maps: https://www.google.com/maps?q=\(latitude),\(longitude)"
        } else {
            message += "📍 Location: Unable to retrieve\n\n"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
        message += "\nTime: \(dateFormatter.string(from: Date()))\n"

        return message
    }

    // MARK: - Audio Recording
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func startAudioRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
            0]
        let audioFilename = documentsPath.appendingPathComponent(
            "emergency_\(Date().timeIntervalSince1970).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingStatus = "Recording..."
        } catch {
            recordingStatus = "Recording failed"
            print("Could not start recording: \(error)")
        }
    }

    func stopAudioRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingStatus = "Recording saved"

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.recordingStatus = "Not Recording"
        }
    }

    // MARK: - Emergency Contacts
    func addContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveContacts()
    }

    func removeContact(at index: Int) {
        emergencyContacts.remove(at: index)
        saveContacts()
    }

    private func saveContacts() {
        if let encoded = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(encoded, forKey: "emergencyContacts")
        }
    }

    private func loadContacts() {
        if let data = UserDefaults.standard.data(forKey: "emergencyContacts"),
            let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data)
        {
            emergencyContacts = contacts
        }
    }

    // MARK: - User Profile
    func saveUserProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }

    private func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
            let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        {
            userProfile = profile
        }
    }

    // MARK: - Emergency History
    private func logEmergencyEvent(location: CLLocation?) {
        let event = EmergencyEvent(
            timestamp: Date(),
            location: location,
            contactsNotified: emergencyContacts.count
        )
        emergencyHistory.insert(event, at: 0)
        saveHistory()
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(emergencyHistory) {
            UserDefaults.standard.set(encoded, forKey: "emergencyHistory")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "emergencyHistory"),
            let history = try? JSONDecoder().decode([EmergencyEvent].self, from: data)
        {
            emergencyHistory = history
        }
    }
}

// MARK: - Models
struct EmergencyContact: Identifiable, Codable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var relationship: String

    init(id: UUID = UUID(), name: String, phoneNumber: String, relationship: String) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
    }
}

struct EmergencyEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?
    let contactsNotified: Int

    init(id: UUID = UUID(), timestamp: Date, location: CLLocation?, contactsNotified: Int) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = location?.coordinate.latitude
        self.longitude = location?.coordinate.longitude
        self.contactsNotified = contactsNotified
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var name: String = "User"
    var age: Int = 25
    var gender: String = "Male"
    var bloodType: String = "AB+"
}

// MARK: - Health Data
struct HealthData {
    var healthScore: Int = 58
    var healthStatus: String = "Average"

    // Vital Signs
    var bodyTemperature: Double = 98.0
    var bloodPressure: String = "Normal"
    var respiratoryRate: String = "30-60 Bpm"
    var pulseRate: Int = 73

    // Health Indicators
    var heartRateStatus: String = "High"
    var weightStatus: String = "Overweight"
    var bpStatus: String = "High"
    var generalStatus: String = "Medium"
}
