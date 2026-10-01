
struct KayakAPI {
    static let baseURL = URL(string: "https://38n8.dvf0.com/")!

    struct Media: Identifiable, Hashable, Decodable {
        let id: String
        let title: String
        let imageURL: URL?
        let detailURL: URL?
        let score: String?
        let year: String?

        enum CodingKeys: String, CodingKey {
            case vod_id, vod_name, vod_title, vod_pic, vod_pic_url, vod_url
            case vod_douban_score, vod_year
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? c.decode(String.self, forKey: .vod_id)) ?? UUID().uuidString
            title = (try? c.decode(String.self, forKey: .vod_name))
                ?? (try? c.decode(String.self, forKey: .vod_title)) ?? "Untitled"
            let rawImage = (try? c.decode(String.self, forKey: .vod_pic_url))
                ?? (try? c.decode(String.self, forKey: .vod_pic))
            imageURL = KayakAPI.makeURL(rawImage)
            detailURL = KayakAPI.makeURL(try? c.decode(String.self, forKey: .vod_url))
            score = try? c.decode(String.self, forKey: .vod_douban_score)
            year = try? c.decode(String.self, forKey: .vod_year)
        }
    }

    struct Topic: Identifiable, Decodable {
        let id: String
        let title: String
        let imageURL: URL?
        let items: [Media]

        init(id: String, title: String, imageURL: URL?, items: [Media]) {
            self.id = id
            self.title = title
            self.imageURL = imageURL
            self.items = items
        }

        enum CodingKeys: String, CodingKey {
            case topic_id, topic_name, topic_title, topic_pic, topic_pic_url, vod_list
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? c.decode(String.self, forKey: .topic_id)) ?? UUID().uuidString
            title = (try? c.decode(String.self, forKey: .topic_name))
                ?? (try? c.decode(String.self, forKey: .topic_title)) ?? "Trending Now"
            let rawImage = (try? c.decode(String.self, forKey: .topic_pic_url))
                ?? (try? c.decode(String.self, forKey: .topic_pic))
            imageURL = KayakAPI.makeURL(rawImage)
            items = (try? c.decode([Media].self, forKey: .vod_list)) ?? []
        }
    }

    enum APIError: LocalizedError {
        case invalidResponse
        case server(String)
        case decoding

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "The server returned an invalid response."
            case .server(let message): return message
            case .decoding: return "The server response could not be read."
            }
        }
    }

    func home() async throws -> ([Topic], [Media]) {
        async let topics = request("api/topic/list", body: [:])
        async let channels = request("api/channel/get_list", body: [:])
        let t = try await topics
        let c = try await channels
        return (extractTopics(from: t), extractMedia(from: c))
    }

    func search(_ query: String) async throws -> [Media] {
        let value = try await request("api/search/result", body: [
            "wd": query,
            "page": "1",
            "limit": "30"
        ])
        return extractMedia(from: value)
    }

    func categories() async throws -> [String] {
        let value = try await request("api/type/get_list", body: [:])
        guard case .object(let object) = value else { return [] }
        for key in ["type_list", "list", "data"] {
            guard let list = object[key], case .array(let array) = list else { continue }
            let names = array.compactMap { item -> String? in
                guard case .object(let o) = item else { return nil }
                return o["type_name"]?.stringValue ?? o["name"]?.stringValue
            }
            if !names.isEmpty { return names }
        }
        return []
    }

    private func request(_ path: String, body: [String: String]) async throws -> JSONValue {
        var request = URLRequest(url: Self.baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("KayakTime", forHTTPHeaderField: "User-Agent")

        if let token = UserDefaults.standard.string(forKey: "kayak.session.token"), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let encoded = body.map { key, value in
            "\(formEncode(key))=\(formEncode(value))"
        }.joined(separator: "&")
        request.httpBody = encoded.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server(String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)")
        }
        guard let json = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            throw APIError.decoding
        }
        return json
    }

    private func extractTopics(from value: JSONValue) -> [Topic] {
        let candidates = objectArrays(from: value, keys: ["topic_list", "list", "data"])
        for candidate in candidates {
            if let data = try? JSONEncoder().encode(candidate),
               let topics = try? JSONDecoder().decode([Topic].self, from: data),
               !topics.isEmpty {
                return topics
            }
        }
        return []
    }

    private func extractMedia(from value: JSONValue) -> [Media] {
        let candidates = objectArrays(from: value, keys: ["vod_list", "list", "data", "results"])
        for candidate in candidates {
            if let data = try? JSONEncoder().encode(candidate),
               let media = try? JSONDecoder().decode([Media].self, from: data),
               !media.isEmpty {
                return media
            }
        }
        return []
    }

    private func objectArrays(from value: JSONValue, keys: [String]) -> [[JSONValue]] {
        if case .array(let array) = value { return [array] }
        guard case .object(let object) = value else { return [] }
        var result: [[JSONValue]] = []
        for key in keys {
            guard let candidate = object[key] else { continue }
            if case .array(let array) = candidate {
                result.append(array)
            } else if case .object(let nested) = candidate {
                for nestedKey in ["vod_list", "topic_list", "list", "results"] {
                    if case .array(let array) = nested[nestedKey] { result.append(array) }
                }
            }
        }
        return result
    }

    private static func makeURL(_ value: String?) -> URL? {
        guard let value, !value.isEmpty else { return nil }
        if let url = URL(string: value), url.scheme != nil { return url }
        return URL(string: value.trimmingCharacters(in: CharacterSet(charactersIn: "/")), relativeTo: baseURL)?.absoluteURL
    }

    private func formEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}

enum JSONValue: Codable, Hashable {
    case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null

    var stringValue: String? {
        switch self {
        case .string(let value): return value
        case .number(let value): return String(value)
        default: return nil
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let value = try? c.decode(Bool.self) { self = .bool(value); return }
        if let value = try? c.decode(Double.self) { self = .number(value); return }
        if let value = try? c.decode(String.self) { self = .string(value); return }
        if let value = try? c.decode([String: JSONValue].self) { self = .object(value); return }
        if let value = try? c.decode([JSONValue].self) { self = .array(value); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON value")
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let value): try c.encode(value)
        case .number(let value): try c.encode(value)
        case .bool(let value): try c.encode(value)
        case .object(let value): try c.encode(value)
        case .array(let value): try c.encode(value)
        case .null: try c.encodeNil()
        }
    }
}
