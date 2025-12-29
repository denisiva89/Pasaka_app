// MockData.swift
import Foundation

struct MockData {
    // Сказка 1: Meža Garā ēna
    static let novaPasakaStory: Story = {
        let slides = (1...6).map { index in
            let indexString = String(format: "%02d", index)
            return Slide(
                id: "nova_slide_\(indexString)",
                imageName: "nova_slide\(indexString).png",
                audioName: "nova_slide\(indexString)_audio.mp3"
            )
        }
        return Story(
            id: "nova_pasaka",
            title: "Meža Garā ēna",
            coverImage: "nova_pasaka_cover.png",
            slides: slides,
            isPremium: false
        )
    }()
    
    // Сказка 2: Zalktis
    static let zalktisStory: Story = {
        let slides = (1...6).map { index in
            let indexString = String(format: "%02d", index)
            return Slide(
                id: "zalktis_slide_\(indexString)",
                imageName: "zalktis_slide\(indexString).png",
                audioName: "zalktis_slide\(indexString)_audio.mp3"
            )
        }
        return Story(
            id: "zalktis",
            title: "Zalktis",
            coverImage: "zalktis_cover.png",
            slides: slides,
            isPremium: false
        )
    }()
    
    // Сказка 3: Trīs Sivēni
    static let trisSiventiniStory: Story = {
        let slides = (1...6).map { index in
            let indexString = String(format: "%02d", index)
            return Slide(
                id: "tris_slide_\(indexString)",
                imageName: "tris_slide\(indexString).png",
                audioName: "tris_slide\(indexString)_audio.m4a"
            )
        }
        return Story(
            id: "tris_siventini",
            title: "Trīs Sivēni",
            coverImage: "tris_siventini_cover.png",
            slides: slides,
            isPremium: false
        )
    }()
    
    static let stories: [Story] = [novaPasakaStory, zalktisStory, trisSiventiniStory]
}
