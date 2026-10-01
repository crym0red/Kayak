import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var results: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func search(_ query: String, token: String?) async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { results = []; return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.fetch(
                path: "api/search/result",
                parameters: ["keyword": text, "page": 1, "limit": 30],
                token: token
            )
            results = APIExtractor.dictionaries(from: response).compactMap(MediaItem.init).reduce(into: []) { result, item in
                if !result.contains(item) { result.append(item) }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SearchView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var model = SearchViewModel()
    @State private var query = ""

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.07, blue: 0.08).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    ForEach(model.results) { item in
                        VStack(alignment: .leading, spacing: 7) {
                            RemoteImage(url: item.imageURL).aspectRatio(0.67, contentMode: .fill).clipShape(RoundedRectangle(cornerRadius: 7))
                            Text(item.title).foregroundStyle(.white).font(.footnote).lineLimit(1)
                        }
                    }
                }
                .padding(16)
            }
            .safeAreaInset(edge: .top) {
                HStack {
                    TextField("Search", text: $query)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .onSubmit { Task { await model.search(query, token: session.token) } }
                    Image(systemName: "magnifyingglass")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(.white.opacity(0.13), in: Capsule())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.02, green: 0.25, blue: 0.33))
            }
        }
    }
}
