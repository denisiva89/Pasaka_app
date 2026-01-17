import SwiftUI
import UIKit

enum NavigationDestination: Hashable {
    case story(Story, Int)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .story(let story, let index):
            hasher.combine(story.id)
            hasher.combine(index)
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.story(let story1, let index1), .story(let story2, let index2)):
            return story1.id == story2.id && index1 == index2
        }
    }
}

struct MainView: View {
    @StateObject private var storyListViewModel: StoryListViewModel
    @StateObject private var storyService: StoryService
    @StateObject private var audioService: AudioService
    @StateObject private var userProgressService: UserProgressService
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var navigationPath = NavigationPath()
    @State private var showContinueOption = false
    @State private var showParentInfo = false  // Исправлено имя переменной
    
    init() {
        let storyService = StoryService()
        let audioService = AudioService()
        let userProgressService = UserProgressService()

        _storyService = StateObject(wrappedValue: storyService)
        _audioService = StateObject(wrappedValue: audioService)
        _userProgressService = StateObject(wrappedValue: userProgressService)
        _storyListViewModel = StateObject(wrappedValue: StoryListViewModel(
            storyService: storyService,
            userProgressService: userProgressService
        ))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background image
                Image("home_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Main "Start" button
                        PasakaButton(title: "Sākt") {
                            print("🎯 Нажата кнопка Sākt")
                            navigationPath.append("storyMenu")
                        }
                        
                        // "Continue" button if saved progress exists
                        if showContinueOption {
                            PasakaButton(title: "Turpināt") {
                                print("🎯 Нажата кнопка Продолжить")
                                continueFromSavedProgress()
                            }
                        }
                    }
                    .offset(x: 15, y: -60)
                    
                    // Parent info link
                    Button("Informācija vecākiem") {
                        showParentInfo = true
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                    .offset(x: 15, y: 130)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationDestination(for: String.self) { route in
                if route == "storyMenu" {
                    StoryMenuView(storyListViewModel: storyListViewModel, navigationPath: $navigationPath)
                        .environmentObject(audioService)
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .story(let story, let initialSlideIndex):
                    SimpleStoryContainer(
                        story: story,
                        audioService: audioService,
                        userProgressService: userProgressService,
                        initialSlideIndex: initialSlideIndex
                    )
                }
            }
            // ИСПРАВЛЕНО: только один overlay для parent info
            .overlay {
                if showParentInfo {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showParentInfo = false
                            }

                        InfoPopup(
                            title: "Informācija vecākiem",
                            message: """
                            Pasaka ir radīta kā mierīga un bērniem draudzīga lasīšanas pieredze.
                            
                            Lietotnē ir neliela latviešu pasaku kolekcija ar ilustrācijām un audio ierakstiem.
                            
                            Tajā nav reklāmu, ārējo saišu vai datu vākšanas.
                            
                            Bērns var lasīt vai klausīties savā tempā, izmantojot vienkāršu un saprotamu navigāciju, kas piemērota jaunākā vecuma lasītājiem.
                            
                            Pasakas mērķis ir veicināt valodas attīstību, iztēli un patstāvīgu lasīšanu drošā digitālā vidē.
                            """,
                            onClose: {
                                showParentInfo = false
                            }
                        )
                        .padding(.horizontal, 24)
                    }
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            print("🏠 MainView появился")
            checkSavedProgress()
        }
    }
    
    private func checkSavedProgress() {
        if storyListViewModel.hasProgress(),
           let lastStoryId = storyListViewModel.getLastStoryId(),
           let story = storyService.getStory(withId: lastStoryId) {
            print("📖 Найден сохраненный прогресс для: \(story.title)")
            showContinueOption = true
        } else {
            showContinueOption = false
        }
    }
    
    private func continueFromSavedProgress() {
        guard let lastStoryId = storyListViewModel.getLastStoryId(),
              let story = storyService.getStory(withId: lastStoryId) else {
            return
        }
        
        let lastSlideIndex = userProgressService.getLastSlideIndex()
        let destination = NavigationDestination.story(story, lastSlideIndex)
        navigationPath.append(destination)
    }
}

// MARK: - Simple Story Container
struct SimpleStoryContainer: View {
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
        
        self._viewModel = StateObject(wrappedValue: StoryPlayerViewModel(
            story: story,
            audioService: audioService,
            userProgressService: userProgressService,
            initialSlideIndex: initialSlideIndex
        ))
    }
    
    var body: some View {
        SlideView(viewModel: viewModel)
    }
}

// MARK: - Info Popup
private struct InfoPopup: View {
    let title: String
    let message: String
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))

            Text(message)
                .font(.system(size: 16))
                .multilineTextAlignment(.leading)

            Button(action: onClose) {
                Text("Aizvērt")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.84, green: 0.51, blue: 0.11))
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: 680)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(radius: 12)
    }
}
