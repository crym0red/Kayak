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
                .padding(.bottom, 4)
                .background(Color.clear)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 4) {
            tab("house.fill", "Home", 0)
            tab("magnifyingglass", "Search", 1)
            tab("chart.bar.fill", "Ranking", 2)
            tab("person.fill", "Me", 3)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(height: 76)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.55), lineWidth: 1))
        .padding(.horizontal, 20)
        .shadow(radius: 18)
    }

    private func tab(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button { selected = index } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .medium))
                    .frame(height: 30)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(selected == index ? .blue : .primary)
            .background(
                selected == index ? .white.opacity(0.35) : .clear,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }
}
