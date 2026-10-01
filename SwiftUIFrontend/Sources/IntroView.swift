import SwiftUI

struct IntroView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("IntroArtwork")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}
