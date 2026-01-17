// MockData.swift
// Данные сказок - добавляй новые сюда
import Foundation

struct MockData {
    // Сказка 1: Zelta putns
    static let zeltaPutnsStory: Story = {
        let slides = (1...12).map { index in
            return Slide(
                id: "zelta_putns_slide_\(index)",
                imageName: "zpi\(index).png",
                audioName: "zpa\(index).mp3"
            )
        }
        return Story(
            id: "zelta_putns",
            title: "Zelta putns",
            coverImage: "zelta_putns_cover.png",
            slides: slides,
            isPremium: false
        )
    }()
    // Сказка 2: Kas apēdis sieru
        static let kasApedisSieruStory: Story = {
            let slides = (1...13).map { index in
                return Slide(
                    id: "kas_apedis_sieru_slide_\(index)",
                    imageName: "kasi\(index).png",
                    audioName: "kasa\(index).mp3"
                )
            }
            return Story(
                id: "kas_apedis_sieru",
                title: "Kas apēdis sieru",
                coverImage: "kasapedissieru_cover.png",
                slides: slides,
                isPremium: false
            )
        }()
    // ШАБЛОН для добавления новой сказки:
    /*
    static let exampleStory: Story = {
        let slides = (1...6).map { index in
            let indexString = String(format: "%02d", index)
            return Slide(
                id: "example_slide_\(indexString)",
                imageName: "example_slide\(indexString).png",
                audioName: "example_slide\(indexString)_audio.mp3"
            )
        }
        return Story(
            id: "example_story",
            title: "Название сказки",
            coverImage: "example_cover.png",
            slides: slides,
            isPremium: false
        )
    }()
    */
    
    // Массив всех сказок (пока пустой)
    static let stories: [Story] = [zeltaPutnsStory,kasApedisSieruStory
        // Добавляй сюда: exampleStory, anotherStory, ...
    ]
}
