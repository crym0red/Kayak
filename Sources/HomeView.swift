import SwiftUI

struct HomeView: View {
    @State private var topics: [KayakAPI.Topic] = []
    @State private var trending: [KayakAPI.Media] = []
    @State private var categories: [String] = []
    @State private var selectedCategory = "Recommend"
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(red: 0.06, green: 0.07, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.top, max(10, proxy.safeAreaInsets.top + 4))

                        categoryStrip

                        if let hero = topics.first(where: { $0.imageURL != nil }) ?? (trending.first.map { media in
                            KayakAPI.Topic(id: "hero", title: media.title, imageURL: media.imageURL, items: trending)
                        }) {
                            HeroCard(topic: hero)
                                .padding(.top, 8)
                        } else if isLoading {
                            SkeletonHero()
                                .padding(.top, 8)
                        }

                        section("Trending Now", items: trending)

                        ForEach(topics.dropFirst()) { topic in
                            section(topic.title, items: topic.items)
                        }

                        if let errorMessage, trending.isEmpty && topics.isEmpty {
                            VStack(spacing: 8) {
                                Text("Unable to load recommendations")
                                    .font(.headline)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }

                        Color.clear.frame(height: 105)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .task { await load() }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("Search")
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
            }
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(.white.opacity(0.12), in: Capsule())

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 22, weight: .medium))
            Image(systemName: "arrow.down.to.line")
                .font(.system(size: 22, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                category("Recommend")
                ForEach(categories, id: \.self) { category($0) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 15)
            .padding(.bottom, 5)
        }
    }

    private func category(_ title: String) -> some View {
        Button { selectedCategory = title } label: {
            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 18, weight: selectedCategory == title ? .semibold : .regular))
                    .foregroundStyle(.white.opacity(selectedCategory == title ? 1 : 0.72))
                Capsule()
                    .fill(selectedCategory == title ? .white : .clear)
                    .frame(width: 20, height: 3)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func section(_ title: String, items: [KayakAPI.Media]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(items) { media in
                            MediaCard(media: media)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 22)
        }
    }

    private func load() async {
        do {
            async let home = KayakAPI().home()
            async let cats = KayakAPI().categories()
            let result = try await home
            let loadedCategories = try? await cats
            await MainActor.run {
                topics = result.0
                trending = result.1.isEmpty ? result.0.first?.items ?? [] : result.1
                categories = loadedCategories ?? []
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

private struct HeroCard: View {
    let topic: KayakAPI.Topic

    var body: some View {
        AsyncImage(url: topic.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Rectangle().fill(.white.opacity(0.08))
            }
        }
        .frame(height: 225)
        .frame(maxWidth: .infinity)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .center)
                .overlay(alignment: .bottomLeading) {
                    Text(topic.title)
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(18)
                }
        }
    }
}

private struct MediaCard: View {
    let media: KayakAPI.Media

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            AsyncImage(url: media.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Rectangle().fill(.white.opacity(0.08))
                }
            }
            .frame(width: 145, height: 205)
            .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(media.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: 145, alignment: .leading)
        }
    }
}

private struct SkeletonHero: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(.white.opacity(0.06))
            .frame(height: 225)
            .overlay(ProgressView().tint(.white))
    }
}
