// StoryPlayerViewModel.swift
// Упрощённая версия для работы с PageCurlView
import Foundation
import SwiftUI
import Combine

class StoryPlayerViewModel: ObservableObject {
    
    // MARK: - Properties
    
    private let _story: Story
    let audioService: AudioService
    private let userProgressService: UserProgressService
    private var cancellables = Set<AnyCancellable>()
    
    // Debug флаг
    let showDebugOverlay: Bool
    
    // Published properties
    @Published var currentSlideIndex: Int
    @Published var isLoading: Bool = false
    @Published var isAudioPlaying: Bool = false
    @Published var isMuted: Bool = false
    
    // MARK: - Computed Properties
    
    var story: Story { _story }
    
    var currentSlide: Slide {
        guard currentSlideIndex >= 0 && currentSlideIndex < _story.slides.count else {
            print("⚠️ Индекс слайда вне диапазона: \(currentSlideIndex)")
            return _story.slides.first!
        }
        return _story.slides[currentSlideIndex]
    }
    
    var hasNextSlide: Bool {
        currentSlideIndex < _story.slides.count - 1
    }
    
    var hasPreviousSlide: Bool {
        currentSlideIndex > 0
    }
    
    var totalSlides: Int {
        _story.slides.count
    }
    
    // MARK: - Initialization
    
    init(story: Story, audioService: AudioService, userProgressService: UserProgressService, initialSlideIndex: Int = 0) {
        self._story = story
        self.audioService = audioService
        self.userProgressService = userProgressService
        self.currentSlideIndex = max(0, min(initialSlideIndex, story.slides.count - 1))
        
        #if DEBUG
        self.showDebugOverlay = false // Установи true для отладки
        #else
        self.showDebugOverlay = false
        #endif
        
        print("🎬 StoryPlayerViewModel инициализирован:")
        print("   - Сказка: \(story.title)")
        print("   - Слайдов: \(story.slides.count)")
        print("   - Начальный индекс: \(self.currentSlideIndex)")
        
        // Подписки на AudioService
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        audioService.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAudioPlaying, on: self)
            .store(in: &cancellables)
        
        audioService.$isMuted
            .receive(on: DispatchQueue.main)
            .assign(to: \.isMuted, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Загружает текущий слайд: останавливает старое аудио, сохраняет прогресс, запускает новое аудио
    func loadCurrentSlide() {
        print("📖 Загружаем слайд \(currentSlideIndex + 1)/\(totalSlides): \(currentSlide.imageName)")
        
        isLoading = true
        
        // Сохраняем прогресс
        userProgressService.saveProgress(storyId: _story.id, slideIndex: currentSlideIndex)
        
        // Останавливаем предыдущее аудио
        audioService.stop()
        
        // Небольшая задержка перед запуском нового аудио
        // (даёт время page curl анимации завершиться)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Воспроизводим аудио текущего слайда
            if let audioURL = self.currentSlide.audioURL() {
                self.audioService.play(audioURL: audioURL)
            } else {
                print("⚠️ Аудио не найдено для слайда: \(self.currentSlide.audioName)")
            }
            
            self.isLoading = false
        }
    }
    
    /// Перезапускает аудио текущего слайда
    func restartAudio() {
        print("🔄 Перезапуск аудио для слайда \(currentSlideIndex + 1)")
        audioService.restart()
    }
    
    /// Переключает звук (mute/unmute)
    func toggleMute() {
        print("🔇 Переключение звука: \(isMuted ? "включить" : "выключить")")
        audioService.toggleMute()
    }
    
    // MARK: - Programmatic Navigation (опционально)
    
    /// Переход к следующему слайду программно
    func goToNextSlide() {
        guard hasNextSlide else { return }
        currentSlideIndex += 1
        loadCurrentSlide()
    }
    
    /// Переход к предыдущему слайду программно
    func goToPreviousSlide() {
        guard hasPreviousSlide else { return }
        currentSlideIndex -= 1
        loadCurrentSlide()
    }
    
    /// Переход к конкретному слайду
    func goToSlide(at index: Int) {
        guard index >= 0 && index < totalSlides else { return }
        currentSlideIndex = index
        loadCurrentSlide()
    }
}
