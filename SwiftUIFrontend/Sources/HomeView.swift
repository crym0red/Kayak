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
            // Do not make the entire screen depend on the optional init call.
            // The original service exposes independent content endpoints.
            async let channel = api.fetch(path: "api/channel/get_list", token: token)
            async let topic = api.fetch(path: "api/topic/list", token: token)
            async let type = api.fetch(path: "api/type/get_list", token: token)

            let channelResponse = try await channel
            let topicResponse = try await topic
            let typeResponse = try await type

            categories = uniqueCategories(
                (APIExtractor.dictionaries(from: channelResponse) +
                 APIExtractor.dictionaries(from: typeResponse))
                    .compactMap(Category.init)
            )

            let parsedTopics = uniqueMedia(
                APIExtractor.dictionaries(from: topicResponse)
                    .compactMap(MediaItem.init)
            )
            topics = parsedTopics
            featured = parsedTopics.first

            var built: [(String, [MediaItem])] = []
            for topic in parsedTopics.prefix(6) {
                let response = try await api.fetch(
                    path: "api/topic/vod_list",
                    parameters: ["topic_id": topic.id, "page": 1, "limit": 12],
                    token: token
                )
                let items = uniqueMedia(
                    APIExtractor.dictionaries(from: response)
                        .compactMap(MediaItem.init)
                )
                if !items.isEmpty { built.append((topic.title, items)) }
            }
            sections = built

            if topics.isEmpty && sections.isEmpty {
                throw APIError(message: "The service returned no catalog items.")
            }
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
        GeometryReader { proxy in
            let topInset = min(max(proxy.safeAreaInsets.top, 0), 59)

            ZStack(alignment: .top) {
                Color(red: 0.04, green: 0.07, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear.frame(height: 1)
                        categoryBar
                        hero
                        content
                    }
                    .padding(.bottom, 96)
                }
                .ignoresSafeArea()

                header(topInset: topInset)
            }
        }
        .task { await model.load(token: session.token) }
    }

    private func header(topInset: CGFloat) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 25, weight: .regular))
                Text("Search")
                    .font(.system(size: 22))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.13), in: Capsule())

            Image(systemName: "clock")
                .font(.system(size: 25))
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))

            Image(systemName: "arrow.down.to.line")
                .font(.system(size: 26))
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.top, topInset + 8)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.40, blue: 0.52),
                    Color(red: 0.04, green: 0.10, blue: 0.13)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                Text("Recommend")
                    .font(.system(size: 27, weight: .semibold))
                    .overlay(alignment: .bottom) {
                        Capsule().frame(width: 24, height: 3).offset(y: 8)
                    }
                ForEach(model.categories.prefix(8)) { category in
                    Text(category.title)
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
        }
        .padding(.top, 138)
    }

    private var hero: some View {
        Group {
            if let item = model.featured {
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(url: item.imageURL)
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.title).font(.system(size: 28, weight: .bold))
                        if let subtitle = item.subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.82)) }
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                }
            } else if model.isLoading {
                ProgressView().tint(.white).frame(maxWidth: .infinity).frame(height: 230).background(.white.opacity(0.06))
            }
        }
    }

    @ViewBuilder private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let error = model.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            if !model.topics.isEmpty { mediaSection(title: "Trending Now", items: model.topics) }
            ForEach(Array(model.sections.enumerated()), id: \.offset) { _, section in
                mediaSection(title: section.0, items: section.1)
            }
        }
        .padding(.top, 22)
    }

    private func mediaSection(title: String, items: [MediaItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 25, weight: .semibold)).foregroundStyle(.white).padding(.horizontal, 16)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 18) {
                ForEach(items.prefix(9)) { item in
                    VStack(alignment: .leading, spacing: 7) {
                        RemoteImage(url: item.imageURL).aspectRatio(0.67, contentMode: .fill).clipShape(RoundedRectangle(cornerRadius: 7))
                        Text(item.title).font(.system(size: 14, weight: .medium)).lineLimit(1).foregroundStyle(.white)
                        if let score = item.score { Text(score).font(.caption).foregroundStyle(.white.opacity(0.65)) }
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
            case .empty: placeholder
            @unknown default: placeholder
            }
        }
    }
    private var placeholder: some View {
        Rectangle().fill(.white.opacity(0.10)).overlay(Image(systemName: "film").foregroundStyle(.white.opacity(0.35)))
    }
}
