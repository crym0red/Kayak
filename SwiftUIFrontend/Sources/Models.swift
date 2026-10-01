import Foundation
import Combine

struct Category: Identifiable, Hashable {
    let id: String
    let title: String

    init?(from object: [String: Any]) {
        guard let id = APIExtractor.firstString(object, keys: ["id", "type_id", "channel_id", "category_id", "topic_id"]),
              let title = APIExtractor.firstString(object, keys: ["title", "name", "type_name", "channel_name", "category_name"]) else {
            return nil
        }
        self.id = id
        self.title = title
    }
}

struct MediaItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let imageURL: URL?
    let score: String?

    init?(from object: [String: Any]) {
        guard let id = APIExtractor.firstString(object, keys: ["id", "vod_id", "video_id", "media_id", "topic_id"]),
              let title = APIExtractor.firstString(object, keys: ["title", "vod_name", "name", "video_name"]) else {
            return nil
        }

        self.id = id
        self.title = title
        self.subtitle = APIExtractor.firstString(object, keys: ["subtitle", "sub_title", "desc", "description", "vod_subtitle"])
        self.imageURL = APIExtractor.firstURL(object, keys: [
            "image", "pic", "poster", "cover", "vod_pic", "vod_pic_thumb", "thumb", "thumbnail", "url"
        ])
        self.score = APIExtractor.firstString(object, keys: ["score", "rating", "vod_score"])
    }
}

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
            // Keep the responses on the MainActor instead of using `async let`
            // with the legacy `[String: Any]` response type. `[String: Any]` is
            // intentionally not Sendable, so concurrent child tasks trigger
            // Swift 6 strict-concurrency diagnostics. The API calls are kept
            // sequential here; the UI remains responsive because `fetch` is
            // asynchronous and performs its network work off the UI thread.
            let channelResponse = try await api.fetch(
                path: "api/channel/get_list",
                token: token
            )
            let topicResponse = try await api.fetch(
                path: "api/topic/list",
                token: token
            )
            let typeResponse = try await api.fetch(
                path: "api/type/get_list",
                token: token
            )

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
