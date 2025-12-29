import SwiftUI

struct SlideView: View {
    @ObservedObject var viewModel: StoryPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Animation state
    @State private var slideOpacity: Double = 1.0
    @State private var isChangingSlide: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color to prevent flash
                Color.black.ignoresSafeArea()
                
                // Current slide with smooth fade
                BundleImage(name: viewModel.currentSlide.imageName)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(slideOpacity)
                    .animation(.easeInOut(duration: 0.4), value: slideOpacity)
                    .id("slide-\(viewModel.currentSlideIndex)")

                // Tap zones for navigation (BEHIND buttons)
                gestureOverlay(geometry: geometry)
                
                // Top controls overlay (ON TOP of gesture overlay)
                VStack {
                    HStack {
                        // Back button (left) - same style as audio controls
                        Control3DButton(
                            icon: "chevron.left",
                            action: {
                                viewModel.audioService.stop()
                                dismiss()
                            }
                        )
                        
                        Spacer()
                        
                        // Audio controls (right)
                        HStack(spacing: 8) {
                            // Restart button
                            Control3DButton(
                                icon: "arrow.clockwise",
                                action: { viewModel.restartAudio() }
                            )
                            
                            // Mute button
                            Control3DButton(
                                icon: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                action: { viewModel.toggleMute() },
                                isActive: !viewModel.isMuted
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 70)
                    
                    Spacer()
                }
                .zIndex(100)

                // Debug overlay (if enabled)
                if viewModel.showDebugOverlay {
                    debugOverlay
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadCurrentSlide()
        }
        .onDisappear {
            viewModel.audioService.stop()
        }
        .gesture(dragGesture)
    }
    
    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                guard !isChangingSlide && !viewModel.isTransitioning else { return }
                
                let threshold: CGFloat = 80
                
                if value.translation.width > threshold {
                    // Swipe right - previous
                    if viewModel.hasPreviousSlide {
                        smoothTransition { viewModel.previousSlide() }
                    } else {
                        viewModel.audioService.stop()
                        dismiss()
                    }
                } else if value.translation.width < -threshold {
                    // Swipe left - next
                    if viewModel.hasNextSlide {
                        smoothTransition { viewModel.nextSlide() }
                    }
                }
            }
    }
    
    // MARK: - Smooth Transition
    private func smoothTransition(action: @escaping () -> Void) {
        isChangingSlide = true
        
        // Fade out
        withAnimation(.easeOut(duration: 0.25)) {
            slideOpacity = 0
        }
        
        // Change slide after fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            action()
            
            // Fade in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeIn(duration: 0.3)) {
                    slideOpacity = 1.0
                }
                
                // Reset state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isChangingSlide = false
                }
            }
        }
    }
    
    // MARK: - Gesture Overlay
    private func gestureOverlay(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left tap zone - previous slide
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    handleTap(direction: .previous)
                }

            // Right tap zone - next slide
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    handleTap(direction: .next)
                }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    private enum TapDirection {
        case previous, next
    }
    
    private func handleTap(direction: TapDirection) {
        guard !isChangingSlide && !viewModel.isTransitioning else { return }
        
        switch direction {
        case .previous:
            if viewModel.hasPreviousSlide {
                smoothTransition { viewModel.previousSlide() }
            } else {
                viewModel.audioService.stop()
                dismiss()
            }
        case .next:
            if viewModel.hasNextSlide {
                smoothTransition { viewModel.nextSlide() }
            }
        }
    }
    
    // MARK: - Debug Overlay
    private var debugOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Слайд: \(viewModel.currentSlideIndex + 1)/\(viewModel.story.slides.count)")
                    Text("Файл: \(viewModel.currentSlide.imageName)")
                    Text("Аудио: \(viewModel.isAudioPlaying ? "▶️" : "⏸️")")
                }
                .font(.caption)
                .padding(8)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            Spacer()
        }
        .padding()
        .padding(.top, 80)
    }
}

// MARK: - Unified 3D Control Button
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
