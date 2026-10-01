import SwiftUI

struct RankingsView: View {
    var body: some View {
        NavigationStack {
            List(1...20, id: \.self) { index in
                HStack {
                    Text("\(index)")
                        .font(.headline)
                    Text("Title \(index)")
                }
            }
            .navigationTitle("Rankings")
        }
    }
}
