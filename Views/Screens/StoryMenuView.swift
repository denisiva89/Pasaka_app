import SwiftUI
import UIKit

struct StoryMenuView: View {
    @ObservedObject var storyListViewModel: StoryListViewModel
    @Binding var navigationPath: NavigationPath

    // 4 columns
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        ZStack {
            // Background image from Assets
            Image("select_pasaka")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    if storyListViewModel.stories.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Ielādē pasakas…")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    } else {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(storyListViewModel.stories, id: \.id) { story in
                                StoryCardView(story: story) {
                                    navigationPath.append(
                                        NavigationDestination.story(story, 0)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 130)
                        .padding(.bottom, 40)
                    }
                }
            }

            // Back button overlay - ОБНОВЛЁННЫЙ СТИЛЬ
            VStack {
                HStack {
                    BackButton3D {
                        navigationPath.removeLast()
                    }
                    .padding(.leading, 24)
                    .padding(.top, 70)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if storyListViewModel.stories.isEmpty {
                storyListViewModel.loadStories()
            }
        }
    }
}

// MARK: - Back Button 3D (такой же стиль как в SlideView)

private struct BackButton3D: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
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

// MARK: - Story Card View

private struct StoryCardView: View {
    let story: Story
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Color.clear
                .aspectRatio(4/3, contentMode: .fit)
                .overlay(
                    BundleImage(name: story.coverImage)
                        .aspectRatio(contentMode: .fill)
                )
                .clipped()
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
