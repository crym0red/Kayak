import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var token: String?

    init() {
        token = UserDefaults.standard.string(forKey: "kayak.session.token")
    }

    func setToken(_ value: String?) {
        token = value
        UserDefaults.standard.set(value, forKey: "kayak.session.token")
    }

    func clear() {
        token = nil
        UserDefaults.standard.removeObject(forKey: "kayak.session.token")
    }
}
