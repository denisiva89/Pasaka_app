import SwiftUI
import UIKit

struct BundleImage: View {
    let name: String
    
    var body: some View {
        if let uiImage = loadImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            // Fallback placeholder
            ZStack {
                Color.gray.opacity(0.2)
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    #if DEBUG
                    Text(name)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    #endif
                }
            }
        }
    }
    
    /// Loads image from bundle, checking multiple locations and extensions
    private func loadImage(named name: String) -> UIImage? {
        let baseName = (name as NSString).deletingPathExtension
        let extensions = ["png", "jpg", "jpeg", "PNG", "JPG", "JPEG"]
        
        // 1. First try UIImage(named:) - works for Assets.xcassets
        if let image = UIImage(named: name) {
            print("✅ BundleImage found via UIImage(named:): \(name)")
            return image
        }
        
        if let image = UIImage(named: baseName) {
            print("✅ BundleImage found via UIImage(named:) baseName: \(baseName)")
            return image
        }
        
        // 2. Try Bundle.main.url with different extensions
        for ext in extensions {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext),
               let image = UIImage(contentsOfFile: url.path) {
                print("✅ BundleImage found via Bundle.main.url: \(baseName).\(ext)")
                return image
            }
        }
        
        // 3. Search in all bundle paths (handles nested folders)
        for ext in extensions {
            let fileName = "\(baseName).\(ext)"
            let allPaths = Bundle.main.paths(forResourcesOfType: ext, inDirectory: nil)
            
            for path in allPaths {
                let url = URL(fileURLWithPath: path)
                if url.lastPathComponent == fileName {
                    if let image = UIImage(contentsOfFile: path) {
                        print("✅ BundleImage found via paths search: \(path)")
                        return image
                    }
                }
            }
        }
        
        // 4. Deep search in subdirectories
        if let resourcePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            
            for ext in extensions {
                let fileName = "\(baseName).\(ext)"
                
                if let enumerator = fileManager.enumerator(atPath: resourcePath) {
                    while let filePath = enumerator.nextObject() as? String {
                        if filePath.hasSuffix(fileName) {
                            let fullPath = (resourcePath as NSString).appendingPathComponent(filePath)
                            if let image = UIImage(contentsOfFile: fullPath) {
                                print("✅ BundleImage found via deep search: \(fullPath)")
                                return image
                            }
                        }
                    }
                }
            }
        }
        
        print("❌ BundleImage NOT found: \(name)")
        return nil
    }
}
