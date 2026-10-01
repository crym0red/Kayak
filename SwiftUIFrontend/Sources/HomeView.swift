import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Recommend")
                        .font(.largeTitle.bold())

                    RoundedRectangle(cornerRadius: 24)
                        .frame(height: 230)
                        .overlay {
                            Text("Featured")
                                .font(.title.bold())
                        }

                    section("Trending Now")
                    section("Recently Added")
                    section("TV Shows")
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func section(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<8, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: 120, height: 175)
                    }
                }
            }
        }
    }
}
