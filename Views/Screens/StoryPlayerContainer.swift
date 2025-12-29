import SwiftUI

struct StoryPlayerContainer: View {
    let story: Story
    let audioService: AudioService
    let userProgressService: UserProgressService
    let initialSlideIndex: Int
    
    @StateObject private var viewModel: StoryPlayerViewModel
    
    init(story: Story, audioService: AudioService, userProgressService: UserProgressService, initialSlideIndex: Int) {
        self.story = story
        self.audioService = audioService
        self.userProgressService = userProgressService
        self.initialSlideIndex = initialSlideIndex
        
        // КРИТИЧЕСКИ ВАЖНО: создаем ViewModel как StateObject
        self._viewModel = StateObject(wrappedValue: StoryPlayerViewModel(
            story: story,
            audioService: audioService,
            userProgressService: userProgressService,
            initialSlideIndex: initialSlideIndex
        ))
        
        print("🎭 StoryPlayerContainer создан для: \(story.title), слайд: \(initialSlideIndex)")
    }
    
    var body: some View {
        SlideView(viewModel: viewModel)
            .id("story-\(story.id)-\(initialSlideIndex)") // Уникальный ID
            .onAppear {
                print("🎭 StoryPlayerContainer появился, currentSlide: \(viewModel.currentSlideIndex)")
            }
    }
}
