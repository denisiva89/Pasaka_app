# Pasaka - iOS fairy tale app

## 1. Vision and goals

Pasaka is a simple iOS app with Latvian fairy tales for kids.

Primary goals:
- Let a child easily choose and read/listen to a fairy tale in Latvian.
- Super simple UI - minimum text, big buttons, intuitive navigation.
- First version is focused on 1 device type (iPhone) but layout should be ready for iPad.

Target user:
- Kids 3-8 years old.
- Parent is usually the one who installs the app and opens the first tale.

Language rules:
- All **code, file names, folders - in English**.
- All **UI text and content inside the app - in Latvian**.

Tech stack:
- iOS, Swift, SwiftUI.
- No external dependencies in MVP (only Apple frameworks).

---

## 2. MVP scope

MVP features:
1. Home screen with the current entry points:
   - Primary button "Sākt" that opens the tales list.
   - Optional "Turpināt" button when saved progress is available; resumes the last tale and slide.
   - Link placeholder "Informācija vecākiem" for future parent info.
2. Tales list screen:
   - For MVP - only one tale: "Trīs sivēntiņi".
   - Simple card with title and cover image; premium flag is supported but unused in mock data.
3. Tale reader screen:
   - Tale is split into 4 horizontal slides (pages).
   - Each slide shows an illustration (no text in the current build).
   - Navigation between slides via swipe or Previous/Next controls.
4. Audio playback:
   - Each slide has its own short audio fragment; playback restarts per slide.
   - Basic play/pause control tied to the active slide; no global progress bar yet.
5. Basic settings:
   - None in the first version. All settings are implicit.

Out of scope for MVP:
- User accounts, profiles, cloud sync.
- Downloads, offline management UI.
- In app purchases or subscriptions.
- Complex settings and parental controls.

---

## 3. App structure and navigation

High level flow (current implementation):

1. App launch
   - `PasakaApp` shows `MainView`.

2. Home screen (`MainView` root)
   - Gradient background and title "Pasaka".
   - Primary button "Sākt" opens the story menu.
   - Secondary button "Turpināt" appears when there is saved progress and resumes the last story/slide.
   - Link placeholder "Informācija vecākiem" (non-functional yet).

3. Tales list (`StoryMenuView`)
   - Scrollable list of story cards with cover image and title.
   - For now:
     - `Story(id: "tris_siventini", title: "Trīs sivēntiņi")` from mock data.
   - Tap on tale -> open `SimpleStoryContainer` at slide 0 (or saved slide when resuming).

4. Tale reader (`SlideView` inside `SimpleStoryContainer`)
   - Shows:
     - current slide illustration (no text overlay),
     - controls:
       - Previous / Next slide,
       - Play / Pause audio per slide.
   - Slides:
     - 4 slides for "Trīs sivēntiņi".
   - Page indicator and debug overlays are present in code; can be adjusted later for polish.

Navigation:
- Uses `NavigationStack` with a string route for the story menu and typed destination for slides.
- Entry options: Home -> Story menu -> Tale reader, or resume directly to Tale reader from Home when progress exists.

---

## 4. Data model

Simple model for tales:

```swift
struct Story: Identifiable {
    let id: String
    let title: String
    let coverImage: String
    let slides: [Slide]
    let isPremium: Bool
}

struct Slide: Identifiable, Equatable {
    let id: String
    let imageName: String // asset name
    let audioName: String // per-slide audio clip
}
```
For MVP:

- Data is hardcoded in `MockData.swift` within `StoryService`.
- Each slide resolves its own image and audio resource (common extensions are auto-resolved).
- Saved progress tracks last opened story and slide index.

5. Audio
For each slide:

- Individual .m4a/.mp3/.wav clips stored in Resources/Audio.
- File names are English and extension-agnostic in code (e.g., `"slide01_audio"`).

Player:

- Simple `AudioService` using AVAudioPlayer.

Responsibilities:

- Load audio by per-slide file name,
- play / pause,
- restart when the slide changes.

ViewModel:

- `StoryPlayerViewModel` manages current slide index and interaction with `AudioService` and `UserProgressService`.

For MVP:

- No background playback.
- Audio stops when the reader screen is closed.

6. UI and design guidelines
General:

Child friendly, but not overloaded.

Large tappable areas, minimum text in buttons.

Colors: soft, not neon.

Fonts: use system rounded font if possible.

Home screen:

- Large title "Pasaka".
- Primary button "Sākt" to open the story menu.
- Optional "Turpināt" button if progress exists.
- Link placeholder "Informācija vecākiem".

Optional small logo or app name "Pasaka".

Tales list:

Simple card with tale title.

Leave space to later show small image.

Tale reader:

Orientation:

design with iPad landscape slide ratio in mind,

but must work on iPhone portrait as well.

Text:

large, good contrast, easy to read for kids / parents.

7. Roadmap
Phase 1 - Prototype (current state)
- App structure: PasakaApp → MainView → StoryMenuView → SlideView inside SimpleStoryContainer.
- Hardcoded data for "Trīs sivēntiņi" with 4 slides and per-slide audio.
- App runs on iOS simulator.

Phase 2 - MVP
- Add 4-5 more tales.
- Add real illustrations.
- Polish slide UI (remove debug overlays, fine-tune controls) and refine audio UX if needed.

Phase 3 - Pre-release
- App icon and launch screen.
- Check layouts on iPhone and iPad.
- Prepare build for TestFlight or .ipa.

8. Code style and conventions
Code in English.

Swift naming:

Types: PasakaApp, MainView, StoryMenuView, SlideView, AudioService, StoryPlayerViewModel.

View models: SomethingViewModel.

Folder structure:

App/ - app entry and configuration.

Views/ - SwiftUI views.

ViewModels/ - view models.

Models/ - data models.

Services/ - audio and other services.

Resources/ - assets, audio files, JSON etc.

Utils/ - helpers.

9. Working with AI assistants (Codex / ChatGPT)
This file is the main source of truth for the project.

When asking Codex for changes:

Mention that the full spec is stored here: PROJECT_OVERVIEW.md.

Ask Codex to respect:

English code only,

Latvian UI text,

existing folder structure.

Typical tasks for Codex:

Implement new views following this spec.

Refactor view models and data layer.

Add new tales based on given text and images.

Improve audio service.
