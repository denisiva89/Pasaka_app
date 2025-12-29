import Foundation
import SwiftUI
import Combine

class StoryPlayerViewModel: ObservableObject {
    private let _story: Story
    let audioService: AudioService
    private let userProgressService: UserProgressService
    private var cancellables = Set<AnyCancellable>()

    let showDebugOverlay: Bool
    
    @Published var currentSlideIndex: Int
    @Published var isLoading: Bool = false
    @Published var isAudioPlaying: Bool = false
    @Published var isMuted: Bool = false
    @Published var isTransitioning: Bool = false
    
    var story: Story { _story }
    
    var currentSlide: Slide {
        guard currentSlideIndex >= 0 && currentSlideIndex < _story.slides.count else {
            print("⚠️ Индекс слайда вне диапазона: \(currentSlideIndex), всего слайдов: \(_story.slides.count)")
            return _story.slides.first!
        }
        return _story.slides[currentSlideIndex]
    }
    
    var hasNextSlide: Bool {
        return currentSlideIndex < _story.slides.count - 1
    }
    
    var hasPreviousSlide: Bool {
        return currentSlideIndex > 0
    }
    
    init(story: Story, audioService: AudioService, userProgressService: UserProgressService, initialSlideIndex: Int = 0) {
        self._story = story
        self.audioService = audioService
        self.userProgressService = userProgressService
        self.currentSlideIndex = max(0, min(initialSlideIndex, story.slides.count - 1))

#if DEBUG
        self.showDebugOverlay = false
#else
        self.showDebugOverlay = false
#endif

        print("🎬 StoryPlayerViewModel инициализирован ОДИН РАЗ:")
        print("   - Сказка: \(story.title)")
        print("   - Слайдов: \(story.slides.count)")
        print("   - Начальный индекс: \(self.currentSlideIndex)")
        
        audioService.$isPlaying
            .assign(to: \.isAudioPlaying, on: self)
            .store(in: &cancellables)
        
        audioService.$isMuted
            .assign(to: \.isMuted, on: self)
            .store(in: &cancellables)
    }
    
    func loadCurrentSlide() {
        print("📖 Загружаем слайд \(currentSlideIndex + 1)/\(_story.slides.count): \(currentSlide.imageName)")
        
        isLoading = true
        
        // Сохраняем прогресс
        userProgressService.saveProgress(storyId: _story.id, slideIndex: currentSlideIndex)
        
        // Останавливаем предыдущее аудио
        audioService.stop()
        
        // ИСПРАВЛЕНО: увеличена пауза перед началом нового аудио для плавности
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in // 1 секунда паузы
            guard let self = self else { return }
            
            print("🎵 Начинаем воспроизведение после паузы")
            
            // Воспроизводим аудио текущего слайда
            if let audioURL = self.currentSlide.audioURL() {
                self.audioService.play(audioURL: audioURL)
            } else {
                print("❌ Не удалось получить URL аудио для слайда")
            }
            
            self.isLoading = false
        }
    }
    
    func nextSlide() {
        guard hasNextSlide && !isTransitioning else {
            print("⚠️ Невозможно перейти к следующему слайду (hasNext: \(hasNextSlide), transitioning: \(isTransitioning))")
            return
        }
        
        print("➡️ Переход к следующему слайду с \(currentSlideIndex) на \(currentSlideIndex + 1)")
        isTransitioning = true
        
        // ДОБАВЛЕНО: плавная остановка текущего аудио
        audioService.stop()
        
        currentSlideIndex += 1
        loadCurrentSlide()
        
        // ИСПРАВЛЕНО: увеличена длительность анимации перехода
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in // 1.2 секунды для полного перехода
            self?.isTransitioning = false
        }
    }
    
    func previousSlide() {
        guard hasPreviousSlide && !isTransitioning else {
            print("⚠️ Невозможно перейти к предыдущему слайду (hasPrev: \(hasPreviousSlide), transitioning: \(isTransitioning))")
            return
        }
        
        print("⬅️ Переход к предыдущему слайду с \(currentSlideIndex) на \(currentSlideIndex - 1)")
        isTransitioning = true
        
        // ДОБАВЛЕНО: плавная остановка текущего аудио
        audioService.stop()
        
        currentSlideIndex -= 1
        loadCurrentSlide()
        
        // ИСПРАВЛЕНО: увеличена длительность анимации перехода
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.isTransitioning = false
        }
    }
    
    func restartAudio() {
        print("🔄 Перезапуск аудио для слайда \(currentSlideIndex + 1)")
        audioService.restart()
    }
    
    func toggleMute() {
        print("🔇 Переключение звука")
        audioService.toggleMute()
    }
}
