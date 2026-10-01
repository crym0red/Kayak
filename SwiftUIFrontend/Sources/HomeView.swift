import Foundation
import Darwin

struct APIConfig {
    static let baseURL = URL(string: "https://38n8.dvf0.com/")!
    static let packageName = "kayaktime"
    static let channelCode = "50009"
    static let appID = "kayaktimea_1000"
}

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class APIClient {
    static let shared = APIClient()
    private let session: URLSession
    private let deviceID: String

    init(session: URLSession = .shared) {
        self.session = session
        if let saved = UserDefaults.standard.string(forKey: "kayak.api.device_id") {
            self.deviceID = saved
        } else {
            let id = UUID().uuidString.lowercased()
            UserDefaults.standard.set(id, forKey: "kayak.api.device_id")
            self.deviceID = id
        }
    }

    func fetch(path: String, parameters: [String: Any] = [:], token: String? = nil) async throws -> [String: Any] {
        let value = try await request(path: path, parameters: parameters, token: token)
        if let object = value as? [String: Any] { return object }
        if let array = value as? [Any] { return ["data": array] }
        return ["data": value]
    }

    func request(path: String, parameters: [String: Any] = [:], token: String? = nil) async throws -> Any {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError(message: "Invalid API path: \(path)")
        }

        var params = baseParameters(token: token)
        for (key, value) in parameters { params[key] = value }

        // The original app exposes these fields in its request contract. The
        // service is legacy and expects form data more reliably than JSON.
        let formData = formEncode(params)
        let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])

        var attempts: [(URLRequest, Data)] = []

        var formRequest = URLRequest(url: url)
        formRequest.httpMethod = "POST"
        formRequest.timeoutInterval = 25
        formRequest.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        formRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        formRequest.setValue("KayakTime/1.0 (iPhone; iOS)", forHTTPHeaderField: "User-Agent")
        formRequest.httpBody = formData
        addAuth(&formRequest, token: token)
        attempts.append((formRequest, formData))

        var jsonRequest = formRequest
        jsonRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        jsonRequest.httpBody = jsonData
        attempts.append((jsonRequest, jsonData))

        var lastMessage = "The server did not return usable data."
        for (request, _) in attempts {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { continue }
                guard (200...299).contains(http.statusCode) else {
                    lastMessage = "API returned HTTP \(http.statusCode)."
                    continue
                }
                if data.isEmpty { return [:] }
                let payload = try Self.decodeServerPayload(data)
                if let message = Self.serverErrorMessage(payload), !message.isEmpty {
                    lastMessage = message
                    continue
                }
                return payload
            } catch {
                lastMessage = error.localizedDescription
            }
        }

        throw APIError(message: lastMessage)
    }

    private func baseParameters(token: String?) -> [String: Any] {
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        return [
            "channel_code": APIConfig.channelCode,
            "sys_platform": "30000",
            "device_id": deviceID,
            "sysrelease": osVersion,
            "mobmodel": Self.machineModel,
            "mob_mfr": "Apple",
            "package_name": APIConfig.packageName,
            "app_id": APIConfig.appID,
            "app_version": "1.0",
            "version": "1.0",
            "api_version": "1.0",
            "is_vvv": "0",
            "is_language": "1",
            "is_display": "1",
            "app_language": locale,
            "lang": locale,
            "token": token ?? ""
        ]
    }

    private func addAuth(_ request: inout URLRequest, token: String?) {
        request.setValue(APIConfig.packageName, forHTTPHeaderField: "X-App-Package")
        request.setValue(APIConfig.channelCode, forHTTPHeaderField: "X-Channel-Code")
        if let token, !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "token")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func formEncode(_ values: [String: Any]) -> Data {
        let body = values.keys.sorted().map { key in
            let value = String(describing: values[key]!)
            return "\(Self.escape(key))=\(Self.escape(value))"
        }.joined(separator: "&")
        return Data(body.utf8)
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
        let preview = String(data: data.prefix(180), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "<non-text response>"
        throw APIError(message: "API returned an unreadable response: \(preview)")
    }

    private static func normalizeJSON(_ value: Any) -> Any {
        if let string = value as? String,
           let nested = string.data(using: .utf8),
           let decoded = try? JSONSerialization.jsonObject(with: nested, options: [.fragmentsAllowed]) {
            return normalizeJSON(decoded)
        }
        if let array = value as? [Any] { return array.map(normalizeJSON) }
        if let dictionary = value as? [String: Any] {
            return dictionary.mapValues(normalizeJSON)
        }
        return value
    }

    private static func serverErrorMessage(_ value: Any) -> String? {
        guard let dict = value as? [String: Any] else { return nil }
        let keys = ["error_msg", "msg", "message", "error", "errmsg"]
        for key in keys {
            if let message = dict[key] as? String, !message.isEmpty {
                let success = (dict["success"] as? Bool) ?? true
                let code = dict["code"] as? Int
                if success == false || (code != nil && code != 0) || message.contains("系统") {
                    return message
                }
            }
        }
        return nil
    }

    private static func escape(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }

    private static var machineModel: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
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
            let priority = ["data", "result", "vod_list", "topic_list", "channel_list", "type_list", "list", "rows", "items", "vod_info"]
            for key in priority where dictionary[key] != nil { walk(dictionary[key]!, into: &output) }
            for (key, child) in dictionary where !priority.contains(key) { _ = key; walk(child, into: &output) }
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

