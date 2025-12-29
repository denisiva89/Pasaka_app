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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var storyService: StoryService
    @StateObject private var audioService: AudioService
    @StateObject private var userProgressService: UserProgressService
    @State private var navigationPath = NavigationPath()
    @State private var showContinueOption = false
    @State private var showEcecInfo = false
    
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
            Image("home_background")
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    
                    
                    VStack(spacing: 20) {
                        // Основная кнопка "Начать"
                        PasakaButton(title: "Sākt") {
                            print("🎯 Нажата кнопка Sākt")
                            navigationPath.append("storyMenu")
                        }
                        
                        // ДОБАВЛЕНО: кнопка "Продолжить" если есть сохраненный прогресс
                        if showContinueOption {
                            PasakaButton(title: "Turpināt") {
                                print("🎯 Нажата кнопка Продолжить")
                                continueFromSavedProgress()
                            }
                        }
                    }
                    .offset(y: -40)
                    Button("Informācija vecākiem") {
                        showEcecInfo = true
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                    .offset(y: +130)

                    
                    Spacer()
                }
                .padding()
            }
            .overlay {
                if showEcecInfo {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                showEcecInfo = false
                            }

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Informācija vecākiem")
                                    .font(.headline)
                                Spacer()
                                Button(action: { showEcecInfo = false }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.primary)
                                }
                                .accessibilityLabel("Aizvērt")
                            }

                            Text("Pasaka ir radīta kā mierīga un bērniem draudzīga lasīšanas pieredze.\n" +
                                 "Lietotnē ir neliela latviešu pasaku kolekcija ar ilustrācijām un audio ierakstiem.\n" +
                                 "Tajā nav reklāmu, ārējo saišu vai datu vākšanas.\n" +
                                 "Bērns var lasīt vai klausīties savā tempā, izmantojot vienkāršu un saprotamu navigāciju, kas piemērota jaunākā vecuma lasītājiem.\n\n" +
                                 "Pasakas mērķis ir veicināt valodas attīstību, iztēli un patstāvīgu lasīšanu drošā digitālā vidē.")
                                .font(.body)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(24)
                        .frame(maxWidth: min(UIScreen.main.bounds.width * 0.8, 600))
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(radius: 10)
                        )
                        .transition(.scale)
                    }
                }
            }
            .navigationDestination(for: String.self) { route in
                Group {
                    if route == "storyMenu" {
                        StoryMenuView(storyListViewModel: storyListViewModel, navigationPath: $navigationPath)
                            .environmentObject(audioService)
                    } else {
                        EmptyView()
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                Group {
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
            }
            .overlay {
                if showEcecInfo {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showEcecInfo = false
                            }

                        InfoPopup(
                            title: "Informācija vecākiem",
                            message: "Pasaka ir radīta kā mierīga un bērniem draudzīga lasīšanas pieredze.\n" +
                                     "Lietotnē ir neliela latviešu pasaku kolekcija ar ilustrācijām un audio ierakstiem.\n" +
                                     "Tajā nav reklāmu, ārējo saišu vai datu vākšanas.\n" +
                                     "Bērns var lasīt vai klausīties savā tempā, izmantojot vienkāršu un saprotamu navigāciju, kas piemērota jaunākā vecuma lasītājiem.\n\n" +
                                     "Pasakas mērķis ir veicināt valodas attīstību, iztēli un patstāvīgu lasīšanu drošā digitālā vidē.",
                            onClose: {
                                showEcecInfo = false
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
    
    // ИСПРАВЛЕНО: не переходим автоматически, а показываем опцию
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
    
    // ДОБАВЛЕНО: функция для продолжения с сохраненного места
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

// SimpleStoryContainer остается без изменений
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
