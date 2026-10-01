import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: [KayakAPI.Media] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.07, blue: 0.08)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                searchField
                    .padding(.top, 14)
                    .padding(.horizontal, 16)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 40)
                } else if results.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: query.isEmpty ? "magnifyingglass" : "film.stack")
                            .font(.system(size: 42))
                        Text(query.isEmpty ? "Search movies and TV shows" : "No results")
                            .font(.headline)
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                    .padding(.horizontal, 24)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(results) { media in
                            SearchMediaCard(media: media)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 110)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .preferredColorScheme(.dark)
        .task(id: query) {
            let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty else {
                results = []
                return
            }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            isLoading = true
            errorMessage = nil
            do {
                results = try await KayakAPI().search(term)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.8))
            TextField("Search", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(.white.opacity(0.12), in: Capsule())
    }
}

private struct SearchMediaCard: View {
    let media: KayakAPI.Media

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            AsyncImage(url: media.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Rectangle().fill(.white.opacity(0.08))
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.70, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(media.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}
