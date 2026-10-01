import Foundation

struct APIConfig {
    static let baseURL = URL(string: "https://38n8.dvf0.com/")!
}

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request(path: String, parameters: [String: Any] = [:], token: String? = nil) async throws -> Any {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError(message: "Invalid API path: \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("KayakTime/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(token, forHTTPHeaderField: "token")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(message: "The server returned an invalid response.")
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError(message: "API returned HTTP \(http.statusCode).")
        }

        guard !data.isEmpty else { return [:] }
        return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    func fetch(path: String, parameters: [String: Any] = [:], token: String? = nil) async throws -> [String: Any] {
        let value = try await request(path: path, parameters: parameters, token: token)
        if let object = value as? [String: Any] { return object }
        return ["data": value]
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
            for child in dictionary.values { walk(child, into: &output) }
        } else if let array = value as? [Any] {
            for child in array { walk(child, into: &output) }
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
