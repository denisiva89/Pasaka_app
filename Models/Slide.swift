import Foundation
import SwiftUI

struct Slide: Identifiable, Equatable {
    let id: String
    let imageName: String
    let audioName: String
    
    init(id: String? = nil, imageName: String, audioName: String) {
        self.id = id ?? UUID().uuidString
        self.imageName = imageName
        self.audioName = audioName
    }
    
    func imageURL(in bundle: Bundle = .main) -> URL? {
        let extensions = ["png", "jpg", "jpeg", "PNG", "JPG", "JPEG"]
        
        // Убираем расширение если оно есть
        let nameWithoutExtension = (imageName as NSString).deletingPathExtension
        
        // Пробуем найти с разными расширениями
        for ext in extensions {
            if let url = bundle.url(forResource: nameWithoutExtension, withExtension: ext) {
                print("✅ Slide image найден: \(nameWithoutExtension).\(ext) -> \(url)")
                return url
            }
        }
        
        // Пробуем исходное имя
        if let url = bundle.url(forResource: imageName, withExtension: nil) {
            print("✅ Slide image найден (исходное имя): \(imageName) -> \(url)")
            return url
        }
        
        print("❌ Slide image НЕ найден: \(imageName)")
        return nil
    }
    
    func audioURL(in bundle: Bundle = .main) -> URL? {
        let extensions = ["m4a", "mp3", "wav", "M4A", "MP3", "WAV"]
        
        // Убираем расширение если оно есть
        let nameWithoutExtension = (audioName as NSString).deletingPathExtension
        
        // Пробуем найти с разными расширениями
        for ext in extensions {
            if let url = bundle.url(forResource: nameWithoutExtension, withExtension: ext) {
                print("✅ Audio найден: \(nameWithoutExtension).\(ext) -> \(url)")
                return url
            }
        }
        
        // Пробуем исходное имя
        if let url = bundle.url(forResource: audioName, withExtension: nil) {
            print("✅ Audio найден (исходное имя): \(audioName) -> \(url)")
            return url
        }
        
        print("❌ Audio НЕ найден: \(audioName)")
        return nil
    }
}
