import SwiftUI

struct RootView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 1: SearchView()
                case 2: RankingsView()
                case 3: ProfileView()
                default: HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            KayakTabBar(selection: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
                .background(.clear)
                .safeAreaPadding(.bottom, 2)
        }
        .background(Color(red: 0.05, green: 0.06, blue: 0.08))
        .ignoresSafeArea()
    }
}

private struct KayakTabBar: View {
    @Binding var selection: Int

    private let items: [(String, String)] = [
        ("house.fill", "Home"),
        ("magnifyingglass", "Search"),
        ("chart.bar.fill", "Rankings"),
        ("person.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    selection = index
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: items[index].0)
                            .font(.system(size: 21, weight: .semibold))
                        Text(items[index].1)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(selection == index ? Color(red: 0.25, green: 0.55, blue: 0.95) : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
    }
}
