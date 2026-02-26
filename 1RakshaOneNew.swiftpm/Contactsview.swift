import Contacts
import ContactsUI
/// A description
import SwiftUI

struct ContactsView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @State private var showingAddContact = false
    @State private var showingRefineContact = false
    @State private var selectedContact: CNContact?

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if emergencyManager.emergencyContacts.isEmpty {
                        emptyStateView
                            .padding(.top, 100)
                    } else {
                        ForEach(emergencyManager.emergencyContacts) { contact in
                            ContactCardView(contact: contact) {
                                withAnimation {
                                    if let index = emergencyManager.emergencyContacts.firstIndex(
                                        where: { $0.id == contact.id })
                                    {
                                        emergencyManager.removeContact(at: index)
                                    }
                                }
                            }
                            .transition(
                                .asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .slide.combined(with: .opacity)))
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Emergency Contacts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    requestContactPermission {
                        showingAddContact = true
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            ContactPickerView { contact in
                let fullName = [contact.givenName, contact.familyName].filter { !$0.isEmpty }
                    .joined(separator: " ")
                let phone = contact.phoneNumbers.first?.value.stringValue ?? ""

                self.selectedContact = contact
                self.showingRefineContact = true
            }
        }
        .sheet(isPresented: $showingRefineContact) {
            if let contact = selectedContact {
                let fullName = [contact.givenName, contact.familyName].filter { !$0.isEmpty }
                    .joined(separator: " ")
                let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                AddContactView(
                    emergencyManager: emergencyManager, initialName: fullName, initialPhone: phone)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "person.2.badge.gearshape.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
            }

            VStack(spacing: 8) {
                Text("No Emergency Contacts")
                    .font(.title2.bold())

                Text("Add trusted contacts who should be notified during an emergency situation.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                requestContactPermission {
                    showingAddContact = true
                }
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Contact")
                }
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
    }

    private func deleteContact(at offsets: IndexSet) {
        withAnimation {
            offsets.forEach { index in
                emergencyManager.removeContact(at: index)
            }
        }
    }

    private func requestContactPermission(completion: @escaping () -> Void) {
        let store = CNContactStore()

        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            completion()
        case .notDetermined:
            store.requestAccess(for: .contacts) { granted, error in
                if granted {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        case .denied, .restricted:
            completion()
        @unknown default:
            completion()
        }
    }
}

struct ContactCardView: View {
    let contact: EmergencyContact
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 54, height: 54)

                Text(String(contact.name.prefix(1)).uppercased())
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)

                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(contact.relationship)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(4)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct AddContactView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var phoneNumber: String
    @State private var relationship = ""

    init(emergencyManager: EmergencyManager, initialName: String = "", initialPhone: String = "") {
        self.emergencyManager = emergencyManager
        _name = State(initialValue: initialName)
        _phoneNumber = State(initialValue: initialPhone)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Illustration
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 100, height: 100)

                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 24)

                        VStack(alignment: .leading, spacing: 20) {
                            modernTextField(title: "Contact Name", icon: "person", text: $name)
                            modernTextField(
                                title: "Phone Number", icon: "phone", text: $phoneNumber,
                                keyboardType: .phonePad)
                            modernTextField(
                                title: "Relationship", icon: "heart", text: $relationship,
                                placeholder: "e.g., Mom, Sister, Friend")
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Refine Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveContact) {
                        Text("Save")
                            .fontWeight(.bold)
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func modernTextField(
        title: String, icon: String, text: Binding<String>, placeholder: String = "",
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)

                TextField(placeholder.isEmpty ? title : placeholder, text: text)
                    .keyboardType(keyboardType)
            }
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private func saveContact() {
        withAnimation {
            let contact = EmergencyContact(
                name: name,
                phoneNumber: phoneNumber,
                relationship: relationship
            )
            emergencyManager.addContact(contact)
        }
        dismiss()
    }
}

#Preview {
    NavigationView {
        ContactsView(emergencyManager: EmergencyManager())
    }
}

struct ContactPickerView: UIViewControllerRepresentable {
    var onSelect: (CNContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context)
    {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onSelect(contact)
        }
    }
}
