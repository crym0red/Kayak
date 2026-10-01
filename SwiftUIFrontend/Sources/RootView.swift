import SwiftUI

struct RootView: View {
    @State private var selected = 0
    @State private var showIntro = true

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case 0: HomeView()
                case 1: SearchView()
                case 2: RankingsView()
                default: ProfileView()
                }
            }
            .ignoresSafeArea()

            bottomBar

            if showIntro {
                IntroView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .ignoresSafeArea()
        .task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.easeOut(duration: 0.35)) {
                showIntro = false
            }
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
        .padding(.bottom, 8)
        .shadow(radius: 18)
    }

    private func tab(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button { selected = index } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selected == index ? .blue : .primary)
            .padding(.vertical, 7)
            .background(selected == index ? .white.opacity(0.35) : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
