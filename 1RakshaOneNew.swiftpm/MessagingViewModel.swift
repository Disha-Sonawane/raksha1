import CoreLocation
import Foundation
import SwiftUI

class MessagingViewModel: ObservableObject {
    @Published var templates: [MessageTemplate] = []
    @Published var customMessage: String = ""
    @Published var includeLocation: Bool = false
    @Published var messageHistory: [MessageHistory] = []
    @Published var selectedRecipients: [String] = []
    @Published var messageToSend: String = ""

    func sendSOSMessage() {
        messageToSend = "SOS! I need help."
    }

    func sendSafeMessage() {
        messageToSend = "I'm safe."
    }

    func sendLocationMessage() {
        messageToSend = "Here is my location."
    }

    func sendTemplate(_ template: MessageTemplate) {
        messageToSend = template.message
    }

    func deleteTemplate(_ template: MessageTemplate) {
        templates.removeAll { $0.id == template.id }
    }

    func sendCustomMessage() {
        messageToSend = customMessage
    }

    func clearHistory() {
        messageHistory.removeAll()
    }

    func recordMessageSent() {
        let history = MessageHistory(
            type: "Custom",
            preview: messageToSend,
            icon: "paperplane.fill",
            color: .blue,
            recipientCount: selectedRecipients.count
        )
        messageHistory.insert(history, at: 0)
    }

    func showAlert(title: String, message: String) {
        print("Alert: \(title) - \(message)")
    }

    func addTemplate(_ template: MessageTemplate) {
        templates.append(template)
    }
}
