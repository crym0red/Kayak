import SwiftUI

struct RankingsView: View {
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.07, blue: 0.08).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text("Rankings").font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                Text("Popular titles from the service").foregroundStyle(.white.opacity(0.65))
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 70)
        }
    }
}
