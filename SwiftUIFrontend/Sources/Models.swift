import Foundation

struct MediaItem: Identifiable, Hashable {
    let id: String
    let title: String
    let imageURL: URL?
    let score: String?
    let subtitle: String?

    init?(object: [String: Any]) {
        guard let id = APIExtractor.firstString(object, keys: ["vod_id", "topic_id", "channel_id", "id", "uuid"]),
              let title = APIExtractor.firstString(object, keys: ["vod_name", "topic_name", "channel_name", "type_name", "title", "name"]) else {
            return nil
        }
        self.id = id
        self.title = title
        self.imageURL = APIExtractor.firstURL(object, keys: [
            "vod_pic_url", "vod_pic", "topic_pic", "pic_url", "pic", "cover", "poster", "image", "thumbnail"
        ])
        self.score = APIExtractor.firstString(object, keys: ["vod_douban_score", "score", "rating"])
        self.subtitle = APIExtractor.firstString(object, keys: ["vod_year", "vod_area", "vod_blurb", "remark", "sub_title"])
    }
}

struct Category: Identifiable, Hashable {
    let id: String
    let title: String

    init?(object: [String: Any]) {
        guard let id = APIExtractor.firstString(object, keys: ["channel_id", "type_id", "id"]),
              let title = APIExtractor.firstString(object, keys: ["channel_name", "type_name", "name", "title"]) else {
            return nil
        }
        self.id = id
        self.title = title
    }
}
