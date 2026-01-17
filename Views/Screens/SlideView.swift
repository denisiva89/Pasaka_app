// SlideView.swift
// Версия без подсказки о перелистывании
import SwiftUI

struct SlideView: View {
    @ObservedObject var viewModel: StoryPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var pageIndex: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Основной контент с page curl эффектом
                PageCurlView(
                    slides: viewModel.story.slides,
                    currentIndex: $pageIndex,
                    onPageChanged: { newIndex in
                        handlePageChange(to: newIndex)
                    }
                )
                .ignoresSafeArea()
                
                // UI элементы поверх page curl
                controlsOverlay(geometry: geometry)
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(true)
        .onAppear {
            pageIndex = viewModel.currentSlideIndex
            viewModel.loadCurrentSlide()
        }
        .onDisappear {
            viewModel.audioService.stop()
        }
        .onChange(of: viewModel.currentSlideIndex) { newIndex in
            if pageIndex != newIndex {
                pageIndex = newIndex
            }
        }
    }
    
    // MARK: - Page Change Handler
    
    private func handlePageChange(to newIndex: Int) {
        guard newIndex != viewModel.currentSlideIndex else { return }
        
        print("📖 Page curl: переход на страницу \(newIndex + 1)")
        
        viewModel.currentSlideIndex = newIndex
        viewModel.loadCurrentSlide()
    }
    
    // MARK: - Controls Overlay
    
    @ViewBuilder
    private func controlsOverlay(geometry: GeometryProxy) -> some View {
        ZStack {
            // Верхняя панель с кнопками
            VStack {
                Spacer()
                    .frame(height: 50)
                
                HStack {
                    // Кнопка "Назад"
                    Control3DButton(
                        icon: "chevron.left",
                        action: {
                            viewModel.audioService.stop()
                            dismiss()
                        }
                    )
                    
                    Spacer()
                    
                    // Аудио контролы
                    HStack(spacing: 8) {
                        Control3DButton(
                            icon: "arrow.clockwise",
                            action: { viewModel.restartAudio() }
                        )
                        
                        Control3DButton(
                            icon: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                            action: { viewModel.toggleMute() },
                            isActive: !viewModel.isMuted
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            
            // Индикатор страницы в нижнем левом углу
            VStack {
                Spacer()
                
                HStack {
                    PageIndicator(
                        current: pageIndex + 1,
                        total: viewModel.story.slides.count
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            
            // УДАЛЕНО: подсказка "Velciet, lai pāršķirtu lapu"
        }
    }
}

// MARK: - Control Button

private struct Control3DButton: View {
    let icon: String
    let action: () -> Void
    var isActive: Bool = true
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
                .frame(width: 38, height: 38)
                .background(
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.3),
                                        Color.black.opacity(0.5)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Circle()
                            .fill(.ultraThinMaterial)
                        
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Page Indicator

private struct PageIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        Text("\(current) / \(total)")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.25))
            )
    }
}

// MARK: - Preview

#if DEBUG
struct SlideView_Previews: PreviewProvider {
    static var previews: some View {
        let story = MockData.stories.first!
        let audioService = AudioService()
        let progressService = UserProgressService()
        let viewModel = StoryPlayerViewModel(
            story: story,
            audioService: audioService,
            userProgressService: progressService
        )
        
        SlideView(viewModel: viewModel)
    }
}
#endif
