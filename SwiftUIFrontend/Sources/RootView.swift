import SwiftUI

struct RootView: View {
    @State private var selected = 0

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.07, blue: 0.08)
                .ignoresSafeArea()

            Group {
                switch selected {
                case 0: HomeView()
                case 1: SearchView()
                case 2: RankingsView()
                default: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
                .padding(.bottom, 8)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tab("house.fill", "Home", 0)
            tab("magnifyingglass", "Search", 1)
            tab("chart.bar.fill", "Ranking", 2)
            tab("person.fill", "Me", 3)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.55), lineWidth: 1))
        .padding(.horizontal, 48)
        .shadow(radius: 18)
    }

    private func tab(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button { selected = index } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 27, weight: .medium))
                Text(title)
                    .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selected == index ? .blue : .primary)
            .padding(.vertical, 7)
            .background(
                selected == index ? .white.opacity(0.35) : .clear,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }
}
