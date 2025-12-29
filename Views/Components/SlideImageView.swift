import SwiftUI

struct SlideImageView: View {
    let slide: Slide
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(2.0)
                    Text("Загружается...")
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
            } else {
                // Используем BundleImage вместо AsyncImage для консистентности
                BundleImage(name: slide.imageName)
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity)
                    .onAppear {
                        print("🖼️ SlideImageView появился для: \(slide.imageName)")
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black) // Убедимся что фон черный
    }
}
