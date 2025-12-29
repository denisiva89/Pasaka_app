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
                        .padding(.top, 130) // Increased - cards lower
                        .padding(.bottom, 40)
                    }
                }
            }

            // Back button overlay
            VStack {
                HStack {
                    Button {
                        navigationPath.removeLast()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(14)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.leading, 24)
                    .padding(.top, 70) // Back button also lower
                    
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
