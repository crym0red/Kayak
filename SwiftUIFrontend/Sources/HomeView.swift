import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var topics: [MediaItem] = []
    @Published var sections: [(String, [MediaItem])] = []
    @Published var featured: MediaItem?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIClient.shared

    func load(token: String?) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let initResponse = api.fetch(path: "api/public/init", token: token)
            async let channelResponse = api.fetch(path: "api/channel/get_list", token: token)
            async let topicResponse = api.fetch(path: "api/topic/list", token: token)
            async let typeResponse = api.fetch(path: "api/type/get_list", token: token)

            _ = try await initResponse
            let channels = try await APIExtractor.dictionaries(from: channelResponse)
            let topics = try await APIExtractor.dictionaries(from: topicResponse)
            let types = try await APIExtractor.dictionaries(from: typeResponse)

            categories = uniqueCategories((channels + types).compactMap(Category.init))
            let parsedTopics = uniqueMedia(topics.compactMap(MediaItem.init))
            self.topics = parsedTopics
            featured = parsedTopics.first

            var built: [(String, [MediaItem])] = []
            for topic in parsedTopics.prefix(5) {
                let response = try await api.fetch(
                    path: "api/topic/vod_list",
                    parameters: ["topic_id": topic.id, "page": 1, "limit": 12],
                    token: token
                )
                let items = uniqueMedia(APIExtractor.dictionaries(from: response).compactMap(MediaItem.init))
                if !items.isEmpty { built.append((topic.title, items)) }
            }
            sections = built
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func uniqueMedia(_ values: [MediaItem]) -> [MediaItem] {
        var seen = Set<String>()
        return values.filter { seen.insert($0.id).inserted }
    }

    private func uniqueCategories(_ values: [Category]) -> [Category] {
        var seen = Set<String>()
        return values.filter { seen.insert($0.id).inserted }
    }
}

struct HomeView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var model = HomeViewModel()

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color(red: 0.04, green: 0.07, blue: 0.08).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        categoryBar
                        hero
                        content
                    }
                    .padding(.bottom, 90)
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .task { await model.load(token: session.token) }
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                Text("Search")
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(.white.opacity(0.13), in: Capsule())

            Image(systemName: "clock")
                .font(.title3)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            Image(systemName: "arrow.down.to.line")
                .font(.title3)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.top, 58)
        .padding(.bottom, 10)
        .background(
            LinearGradient(colors: [Color(red: 0.02, green: 0.40, blue: 0.52), Color(red: 0.04, green: 0.10, blue: 0.13)], startPoint: .top, endPoint: .bottom)
        )
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                Text("Recommend")
                    .font(.system(size: 25, weight: .semibold))
                    .overlay(alignment: .bottom) { Capsule().frame(width: 22, height: 3).offset(y: 7) }
                ForEach(model.categories.prefix(8)) { category in
                    Text(category.title)
                        .font(.system(size: 21))
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var hero: some View {
        Group {
            if let item = model.featured {
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(url: item.imageURL)
                        .frame(height: 225)
                        .clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 28, weight: .bold))
                        if let subtitle = item.subtitle { Text(subtitle).font(.subheadline) }
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                }
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(.white.opacity(0.06))
                    .frame(height: 225)
            }
        }
    }

    @ViewBuilder private var content: some View {
        VStack(alignment: .leading, spacing: 22) {
            if model.isLoading && model.sections.isEmpty {
                ProgressView().tint(.white).frame(maxWidth: .infinity).padding(40)
            }
            if let error = model.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.white.opacity(0.65)).padding(.horizontal, 16)
            }
            if !model.topics.isEmpty {
                mediaSection(title: "Trending Now", items: model.topics)
            }
            ForEach(Array(model.sections.enumerated()), id: \.offset) { _, section in
                mediaSection(title: section.0, items: section.1)
            }
        }
        .padding(.top, 22)
    }

    private func mediaSection(title: String, items: [MediaItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                ForEach(items.prefix(9)) { item in
                    VStack(alignment: .leading, spacing: 7) {
                        RemoteImage(url: item.imageURL)
                            .aspectRatio(0.67, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                            .foregroundStyle(.white)
                        if let score = item.score {
                            Text(score).font(.caption).foregroundStyle(.white.opacity(0.65))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct RemoteImage: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            case .failure: placeholder
            default: placeholder
            }
        }
    }

    private var placeholder: some View {
        Rectangle().fill(.white.opacity(0.10)).overlay(Image(systemName: "film").foregroundStyle(.white.opacity(0.35)))
    }
}
