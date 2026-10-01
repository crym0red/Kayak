import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.07, blue: 0.08).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                Text("Profile").font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                if session.token == nil {
                    Text("Not signed in").foregroundStyle(.white.opacity(0.65))
                } else {
                    Text("Signed in").foregroundStyle(.white.opacity(0.65))
                    Button("Sign out") { session.clear() }
                        .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 70)
        }
    }
}
