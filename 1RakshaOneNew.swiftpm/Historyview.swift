import SwiftUI
import MapKit

struct HistoryView: View {
    @ObservedObject var emergencyManager: EmergencyManager
    
    var body: some View {
        List {
            ForEach(emergencyManager.emergencyHistory) { event in
                NavigationLink(destination: EventDetailView(event: event)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formattedDate(event.timestamp))
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            
                            if let lat = event.latitude, let lon = event.longitude {
                                Text("\(lat, specifier: "%.6f"), \(lon, specifier: "%.6f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Location unavailable")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("\(event.contactsNotified) contact(s) notified")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Emergency History")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if emergencyManager.emergencyHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Emergency Events")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your emergency alerts will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct EventDetailView: View {
    let event: EmergencyEvent
    @State private var region: MKCoordinateRegion
    
    init(event: EmergencyEvent) {
        self.event = event
        
        if let lat = event.latitude, let lon = event.longitude {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Map
                if let lat = event.latitude, let lon = event.longitude {
                    Map(coordinateRegion: $region, annotationItems: [event]) { item in
                        MapMarker(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), tint: .red)
                    }
                    .frame(height: 250)
                    .cornerRadius(12)
                    .padding()
                }
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(icon: "clock.fill", title: "Time", value: formattedDate(event.timestamp))
                    
                    if let lat = event.latitude, let lon = event.longitude {
                        // We format the numbers into strings first to avoid the specifier error
                        DetailRow(icon: "mappin.circle.fill", title: "Latitude", value: String(format: "%.6f", lat))
                        DetailRow(icon: "mappin.circle.fill", title: "Longitude", value: String(format: "%.6f", lon))
                        
                        Button(action: {
                            openInMaps(latitude: lat, longitude: lon)
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Open in Maps")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    } else {
                        DetailRow(icon: "location.slash.fill", title: "Location", value: "Not available")
                    }
                    
                    DetailRow(icon: "person.2.fill", title: "Contacts Notified", value: "\(event.contactsNotified)")
                }
                .padding()
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy 'at' HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func openInMaps(latitude: Double, longitude: Double) {
        let urlString = "https://maps.apple.com/?q=\(latitude),\(longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        HistoryView(emergencyManager: EmergencyManager())
    }
}
