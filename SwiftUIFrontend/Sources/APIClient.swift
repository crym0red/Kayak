import Foundation

struct APIConfig {
    static let baseURL = URL(string: "https://38n8.dvf0.com/")!
}

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// The original service accepts POST requests. Some responses are wrapped,
    /// returned as a JSON string, or use a form body, so decoding is deliberately
    /// tolerant instead of relying on one Codable response shape.
    func request(path: String, parameters: [String: Any] = [:], token: String? = nil) async throws -> Any {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError(message: "Invalid API path: \(path)")
        }

        let jsonBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        let formBody = parameters
            .map { key, value in
                "\(Self.escape(key))=\(Self.escape(String(describing: value)))"
            }
            .joined(separator: "&")
            .data(using: .utf8) ?? Data()

        // Try the service's JSON request shape first, then the common
        // application/x-www-form-urlencoded shape used by legacy API clients.
        var lastError: Error?
        for (body, contentType) in [(jsonBody, "application/json; charset=utf-8"),
                                    (formBody, "application/x-www-form-urlencoded; charset=utf-8")] {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 25
            request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.setValue("KayakTime/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
            if let token, !token.isEmpty {
                request.setValue(token, forHTTPHeaderField: "token")
                request.setValue("Token token=\"\(token)\"", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = body

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw APIError(message: "The server returned an invalid response.")
                }
                guard (200...299).contains(http.statusCode) else {
                    throw APIError(message: "API returned HTTP \(http.statusCode).")
                }

                guard !data.isEmpty else { return [:] }
                return try Self.decodeServerPayload(data)
            } catch {
                lastError = error
            }
        }

        throw lastError ?? APIError(message: "The server returned data in an unsupported format.")
    }

    func fetch(path: String, parameters: [String: Any] = [:], token: String? = nil) async throws -> [String: Any] {
        let value = try await request(path: path, parameters: parameters, token: token)
        if let object = value as? [String: Any] { return object }
        if let array = value as? [Any] { return ["data": array] }
        return ["data": value]
    }

    private static func decodeServerPayload(_ data: Data) throws -> Any {
        var candidates: [Data] = [data]
        if let text = String(data: data, encoding: .utf8) {
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\u{FEFF}", with: "")
            if let cleanedData = cleaned.data(using: .utf8), cleanedData != data {
                candidates.append(cleanedData)
            }
        }

        for candidate in candidates {
            if let value = try? JSONSerialization.jsonObject(with: candidate, options: [.fragmentsAllowed]) {
                return normalizeJSON(value)
            }
        }

        let preview = String(data: data.prefix(180), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "<non-text response>"
        throw APIError(message: "The API response was not valid JSON: \(preview)")
    }

    private static func normalizeJSON(_ value: Any) -> Any {
        // Some legacy gateways return JSON encoded as a JSON string.
        if let string = value as? String,
           let nested = string.data(using: .utf8),
           let decoded = try? JSONSerialization.jsonObject(with: nested, options: [.fragmentsAllowed]) {
            return normalizeJSON(decoded)
        }

        if let array = value as? [Any] {
            return array.map(normalizeJSON)
        }

        if let dictionary = value as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, child) in dictionary {
                result[key] = normalizeJSON(child)
            }
            return result
        }

        return value
    }

    private static func escape(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}

struct APIExtractor {
    static func dictionaries(from value: Any) -> [[String: Any]] {
        var output: [[String: Any]] = []
        walk(value, into: &output)
        return output
    }

    private static func walk(_ value: Any, into output: inout [[String: Any]]) {
        if let dictionary = value as? [String: Any] {
            output.append(dictionary)

            // Explicitly walk common API envelope keys first.
            for key in ["data", "result", "list", "vod_list", "topic_list", "channel_list", "type_list", "rows", "items"] {
                if let child = dictionary[key] {
                    walk(child, into: &output)
                }
            }

            for (key, child) in dictionary where !["data", "result", "list", "vod_list", "topic_list", "channel_list", "type_list", "rows", "items"].contains(key) {
                _ = key
                walk(child, into: &output)
            }
        } else if let array = value as? [Any] {
            for child in array { walk(child, into: &output) }
        } else if let string = value as? String,
                  let data = string.data(using: .utf8),
                  let decoded = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
            walk(decoded, into: &output)
        }
    }

    static func firstString(_ object: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = object[key] as? String, !value.isEmpty { return value }
            if let value = object[key] as? NSNumber { return value.stringValue }
        }
        return nil
    }

    static func firstURL(_ object: [String: Any], keys: [String]) -> URL? {
        guard let value = firstString(object, keys: keys) else { return nil }
        if let url = URL(string: value), url.scheme != nil { return url }
        return URL(string: value, relativeTo: APIConfig.baseURL)
    }
}
