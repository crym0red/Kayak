import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var results: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func search(_ query: String, token: String?) async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { results = []; errorMessage = nil; return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.fetch(
                path: "api/search/result",
                parameters: ["keyword": text, "page": 1, "limit": 30],
                token: token
            )
            results = APIExtractor.dictionaries(from: response)
                .compactMap(MediaItem.init)
                .reduce(into: []) { result, item in if !result.contains(item) { result.append(item) } }
        } catch { errorMessage = error.localizedDescription }
    }
}

struct SearchView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var model = SearchViewModel()
    @State private var query = ""

    var body: some View {
        GeometryReader { proxy in
            let topInset = min(max(proxy.safeAreaInsets.top, 0), 59)
            ZStack(alignment: .top) {
                Color(red: 0.04, green: 0.07, blue: 0.08).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 1)
                        if let error = model.errorMessage {
                            Text(error).foregroundStyle(.white.opacity(0.75)).padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 18) {
                            ForEach(model.results) { item in
                                VStack(alignment: .leading, spacing: 7) {
                                    RemoteImage(url: item.imageURL).aspectRatio(0.67, contentMode: .fill).clipShape(RoundedRectangle(cornerRadius: 7))
                                    Text(item.title).foregroundStyle(.white).font(.footnote).lineLimit(1)
                                }
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 96)
                    }
                    .padding(.top, 80)
                }
                .ignoresSafeArea()

                searchBar(topInset: topInset)
            }
        }
    }

    private func searchBar(topInset: CGFloat) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
            TextField("Search", text: $query)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit { Task { await model.search(query, token: session.token) } }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(.white.opacity(0.13), in: Capsule())
        .padding(.horizontal, 16)
        .padding(.top, topInset + 8)
        .padding(.bottom, 12)
        .background(
            LinearGradient(colors: [Color(red: 0.02, green: 0.40, blue: 0.52), Color(red: 0.04, green: 0.10, blue: 0.13)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }
}
