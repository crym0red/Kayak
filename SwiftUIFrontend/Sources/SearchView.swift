import SwiftUI

struct SearchView: View {
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Text("Search movies and TV shows")
                        .foregroundStyle(.secondary)
                }
            }
            .searchable(text: $query)
            .navigationTitle("Search")
        }
    }
}
