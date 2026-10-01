import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Text("Existing authentication/session layer remains separate from this UI.")
                }
            }
            .navigationTitle("Profile")
        }
    }
}
