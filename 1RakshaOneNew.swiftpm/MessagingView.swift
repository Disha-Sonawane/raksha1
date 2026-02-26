//
//  Messagingview .swift
//  RakshaOne
//
//  Created by students on 26/02/26.
//

//
//  MessagingView.swift
//  RakshaOne
//
//  Complete messaging interface for emergency communications
//

import MessageUI
import SwiftUI

struct MessagingView: View {
    @StateObject private var viewModel = MessagingViewModel()
    @State private var showingMessageComposer = false
    @State private var showingTemplateEditor = false
    @State private var selectedTemplate: MessageTemplate?
    @State private var showUnavailableAlert = false

    private func trySendMessage() {
        if MFMessageComposeViewController.canSendText() {
            showingMessageComposer = true
        } else {
            showUnavailableAlert = true
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Send Section
                    quickSendSection

                    // Message Templates
                    templatesSection

                    // Custom Message
                    customMessageSection

                    // Message History
                    messageHistorySection
                }
                .padding()
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingTemplateEditor = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingMessageComposer) {
                if MFMessageComposeViewController.canSendText() {
                    MessageComposeSheet(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingTemplateEditor) {
                TemplateEditorView(viewModel: viewModel)
            }
            .alert("SMS Not Available", isPresented: $showUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "This device cannot send SMS messages. Please use a device with SMS capability."
                )
            }
        }
    }

    // MARK: - Quick Send Section
    private var quickSendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡ Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                // SOS Message
                MessageQuickActionButton(
                    icon: "exclamationmark.triangle.fill",
                    title: "SOS Alert",
                    color: .red
                ) {
                    viewModel.sendSOSMessage()
                    trySendMessage()
                }

                // I'm Safe Message
                MessageQuickActionButton(
                    icon: "checkmark.shield.fill",
                    title: "I'm Safe",
                    color: .green
                ) {
                    viewModel.sendSafeMessage()
                    trySendMessage()
                }

                // Location Share
                MessageQuickActionButton(
                    icon: "location.fill",
                    title: "Location",
                    color: .blue
                ) {
                    viewModel.sendLocationMessage()
                    trySendMessage()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }

    // MARK: - Templates Section
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📝 Message Templates")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.templates.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.templates.isEmpty {
                EmptyTemplatesView()
            } else {
                ForEach(viewModel.templates) { template in
                    TemplateCard(
                        template: template,
                        onSend: {
                            viewModel.sendTemplate(template)
                            trySendMessage()
                        },
                        onEdit: {
                            selectedTemplate = template
                            showingTemplateEditor = true
                        },
                        onDelete: {
                            viewModel.deleteTemplate(template)
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }

    // MARK: - Custom Message Section
    private var customMessageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("✍️ Custom Message")
                .font(.headline)

            TextEditor(text: $viewModel.customMessage)
                .frame(height: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )

            HStack {
                Toggle("Include Location", isOn: $viewModel.includeLocation)
                    .font(.subheadline)
            }

            Button(action: {
                viewModel.sendCustomMessage()
                trySendMessage()
            }) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Send Custom Message")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }

    // MARK: - Message History Section
    private var messageHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📜 Recent Messages")
                    .font(.headline)
                Spacer()
                Button(action: viewModel.clearHistory) {
                    Text("Clear")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            if viewModel.messageHistory.isEmpty {
                Text("No messages sent yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.messageHistory) { message in
                    MessageHistoryCard(message: message)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
}

// MARK: - Quick Action Button
struct MessageQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: MessageTemplate
    let onSend: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.icon)
                    .font(.title3)
                Text(template.name)
                    .font(.headline)
                Spacer()
                Menu {
                    Button(action: onSend) {
                        Label("Send Now", systemImage: "paperplane.fill")
                    }
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }

            Text(template.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                if template.includeLocation {
                    Label("Location", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                Spacer()
                Button(action: onSend) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Empty Templates View
struct EmptyTemplatesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No Templates Yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Tap + to create your first message template")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Message History Card
struct MessageHistoryCard: View {
    let message: MessageHistory

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Image(systemName: message.icon)
                    .font(.title3)
                    .foregroundColor(message.color)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(message.type)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(message.preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(message.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(message.recipientCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("contacts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Message Compose Sheet
struct MessageComposeSheet: UIViewControllerRepresentable {
    @ObservedObject var viewModel: MessagingViewModel
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = viewModel.selectedRecipients
        controller.body = viewModel.messageToSend
        return controller
    }

    func updateUIViewController(
        _ uiViewController: MFMessageComposeViewController, context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    class Coordinator: NSObject, @MainActor MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeSheet

        init(_ parent: MessageComposeSheet) {
            self.parent = parent
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult
        ) {
            let parent = self.parent
            let viewModel = parent.viewModel
            parent.presentationMode.wrappedValue.dismiss()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .sent:
                    viewModel.recordMessageSent()
                case .failed:
                    viewModel.showAlert(
                        title: "Failed", message: "Failed to send message")
                case .cancelled:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - Template Editor View
struct TemplateEditorView: View {
    @ObservedObject var viewModel: MessagingViewModel
    @Environment(\.dismiss) var dismiss

    @State private var templateName = ""
    @State private var templateMessage = ""
    @State private var templateIcon = "💬"
    @State private var includeLocation = false

    let icons = ["💬", "🆘", "✅", "📍", "⚠️", "🚨", "💙", "🏠", "🚗", "✈️"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Template Details")) {
                    TextField("Template Name", text: $templateName)

                    HStack {
                        Text("Icon")
                        Spacer()
                        Picker("Icon", selection: $templateIcon) {
                            ForEach(icons, id: \.self) { icon in
                                Text(icon).tag(icon)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section(header: Text("Message Content")) {
                    TextEditor(text: $templateMessage)
                        .frame(height: 150)

                    Toggle("Include GPS Location", isOn: $includeLocation)
                }

                Section(header: Text("Preview")) {
                    Text(
                        templateMessage.isEmpty ? "Your message will appear here" : templateMessage
                    )
                    .font(.subheadline)
                    .foregroundColor(templateMessage.isEmpty ? .secondary : .primary)

                    if includeLocation {
                        Text("📍 Location: [GPS coordinates will be inserted]")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(templateName.isEmpty || templateMessage.isEmpty)
                }
            }
        }
    }

    private func saveTemplate() {
        let template = MessageTemplate(
            name: templateName,
            message: templateMessage,
            icon: templateIcon,
            includeLocation: includeLocation
        )
        viewModel.addTemplate(template)
        dismiss()
    }
}

// MARK: - Models
struct MessageTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let message: String
    let icon: String
    let includeLocation: Bool

    init(id: UUID = UUID(), name: String, message: String, icon: String, includeLocation: Bool) {
        self.id = id
        self.name = name
        self.message = message
        self.icon = icon
        self.includeLocation = includeLocation
    }
}

struct MessageHistory: Identifiable, Codable {
    let id: UUID
    let type: String
    let preview: String
    let icon: String
    let colorName: String
    let recipientCount: Int
    let timestamp: Date

    var color: Color {
        switch colorName {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        default: return .gray
        }
    }

    init(
        id: UUID = UUID(), type: String, preview: String, icon: String, color: Color,
        recipientCount: Int
    ) {
        self.id = id
        self.type = type
        self.preview = preview
        self.icon = icon
        self.recipientCount = recipientCount
        self.timestamp = Date()

        // Convert color to string for Codable
        switch color {
        case .red: self.colorName = "red"
        case .green: self.colorName = "green"
        case .blue: self.colorName = "blue"
        case .orange: self.colorName = "orange"
        default: self.colorName = "gray"
        }
    }
}

struct MessagingView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingView()
    }
}
