// NarrationTextService.swift
// Сервис для загрузки и парсинга текста диктора из RTF файлов

import Foundation
import UIKit

class NarrationTextService {
    
    // MARK: - Singleton
    static let shared = NarrationTextService()
    
    private init() {}
    
    // MARK: - Cache
    /// Кеш: [storyId: [slideNumber: narrationText]]
    private var cache: [String: [Int: String]] = [:]
    
    // MARK: - Public API
    
    /// Получить текст диктора для конкретного слайда
    /// - Parameters:
    ///   - story: Сказка
    ///   - slideNumber: Номер слайда (1-based)
    /// - Returns: Текст на латышском или nil если не найден
    func narrationText(for story: Story, slideNumber: Int) -> String? {
        // Проверяем кеш
        if let storyCache = cache[story.id], let text = storyCache[slideNumber] {
            print("📖 NarrationTextService: кеш hit для \(story.id) слайд \(slideNumber)")
            return text
        }
        
        // Загружаем и парсим RTF если еще не в кеше
        if cache[story.id] == nil {
            loadAndParseRTF(for: story)
        }
        
        return cache[story.id]?[slideNumber]
    }
    
    /// Получить текст диктора по имени слайда (автоматически извлекает номер)
    /// - Parameters:
    ///   - story: Сказка
    ///   - slideName: Имя файла слайда (например "nova_slide03.png")
    /// - Returns: Текст на латышском или nil
    func narrationText(for story: Story, slideName: String) -> String? {
        guard let slideNumber = extractSlideNumber(from: slideName) else {
            print("⚠️ NarrationTextService: не удалось извлечь номер слайда из \(slideName)")
            return nil
        }
        return narrationText(for: story, slideNumber: slideNumber)
    }
    
    /// Очистить кеш (например при низкой памяти)
    func clearCache() {
        cache.removeAll()
        print("🗑️ NarrationTextService: кеш очищен")
    }
    
    // MARK: - Private Methods
    
    /// Извлечь номер слайда из имени файла
    /// Правило: берем последовательность цифр в конце имени (до расширения)
    /// Примеры: "nova_slide03.png" -> 3, "slide_12" -> 12, "ABCDEF3" -> 3
    private func extractSlideNumber(from name: String) -> Int? {
        // Убираем расширение
        let baseName = (name as NSString).deletingPathExtension
        
        // Ищем цифры в конце строки
        let pattern = "(\\d+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(baseName.startIndex..<baseName.endIndex, in: baseName)
        guard let match = regex.firstMatch(in: baseName, options: [], range: range) else {
            return nil
        }
        
        guard let numberRange = Range(match.range(at: 1), in: baseName) else {
            return nil
        }
        
        let numberString = String(baseName[numberRange])
        return Int(numberString)
    }
    
    /// Загрузить и распарсить RTF файл для сказки
    private func loadAndParseRTF(for story: Story) {
        print("📂 NarrationTextService: загружаю RTF для \(story.id)")
        
        // Пробуем найти RTF файл
        guard let rtfURL = findRTFFile(for: story) else {
            print("❌ NarrationTextService: RTF файл не найден для \(story.id)")
            cache[story.id] = [:] // Пустой кеш чтобы не искать повторно
            return
        }
        
        // Читаем RTF как NSAttributedString
        guard let plainText = loadRTFAsPlainText(url: rtfURL) else {
            print("❌ NarrationTextService: не удалось прочитать RTF файл")
            cache[story.id] = [:]
            return
        }
        
        // Парсим текст по слайдам
        let parsed = parseNarrationTexts(from: plainText)
        cache[story.id] = parsed
        
        print("✅ NarrationTextService: загружено \(parsed.count) текстов для \(story.id)")
    }
    
    /// Найти RTF файл для сказки в bundle
    private func findRTFFile(for story: Story) -> URL? {
        let possibleNames = [
            "narration",
            "text",
            "\(story.id)_narration",
            "\(story.id)_text",
            story.id
        ]
        
        let extensions = ["rtf", "RTF"]
        
        // Пробуем найти файл с разными именами
        for name in possibleNames {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    print("✅ Найден RTF: \(name).\(ext)")
                    return url
                }
            }
        }
        
        // Глубокий поиск в bundle
        if let resourcePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            
            if let enumerator = fileManager.enumerator(atPath: resourcePath) {
                while let filePath = enumerator.nextObject() as? String {
                    // Ищем RTF файлы, связанные со story.id
                    if filePath.lowercased().hasSuffix(".rtf") {
                        // Проверяем, содержит ли путь идентификатор сказки
                        let lowerPath = filePath.lowercased()
                        let lowerStoryId = story.id.lowercased()
                        
                        // Сопоставляем по частям идентификатора
                        // nova_pasaka -> nova, zalktis -> zalktis, tris_siventini -> tris
                        let storyKeywords = lowerStoryId.components(separatedBy: "_")
                        
                        for keyword in storyKeywords {
                            if keyword.count >= 3 && lowerPath.contains(keyword) {
                                let fullPath = (resourcePath as NSString).appendingPathComponent(filePath)
                                print("✅ Найден RTF через deep search: \(filePath)")
                                return URL(fileURLWithPath: fullPath)
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Загрузить RTF файл и конвертировать в plain text
    private func loadRTFAsPlainText(url: URL) -> String? {
        do {
            let data = try Data(contentsOf: url)
            
            // Пробуем как RTF
            if let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            ) {
                return attributedString.string
            }
            
            // Fallback: пробуем как plain text
            if let plainString = String(data: data, encoding: .utf8) {
                return plainString
            }
            
            return nil
        } catch {
            print("❌ Ошибка чтения RTF: \(error)")
            return nil
        }
    }
    
    /// Парсить текст и извлечь Narration text (LV) для каждого слайда
    private func parseNarrationTexts(from text: String) -> [Int: String] {
        var result: [Int: String] = [:]
        
        // Разбиваем на строки
        let lines = text.components(separatedBy: .newlines)
        
        var currentSlideNumber: Int? = nil
        var isCollectingNarration = false
        var narrationLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Проверяем начало нового слайда: "Slide N" или "Slide N (..."
            if let slideNum = extractSlideHeader(from: trimmedLine) {
                // Сохраняем предыдущий narration если был
                if let prevSlide = currentSlideNumber, !narrationLines.isEmpty {
                    let narration = narrationLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !narration.isEmpty {
                        result[prevSlide] = cleanupNarrationText(narration)
                    }
                }
                
                // Начинаем новый слайд
                currentSlideNumber = slideNum
                isCollectingNarration = false
                narrationLines = []
                continue
            }
            
            // Проверяем начало секции narration
            if trimmedLine.contains("Narration text (LV):") {
                isCollectingNarration = true
                
                // Может быть текст на той же строке после двоеточия
                if let colonIndex = trimmedLine.range(of: "Narration text (LV):")?.upperBound {
                    let afterColon = String(trimmedLine[colonIndex...]).trimmingCharacters(in: .whitespaces)
                    if !afterColon.isEmpty {
                        narrationLines.append(afterColon)
                    }
                }
                continue
            }
            
            // Проверяем конец секции narration (начало другой секции)
            if isCollectingNarration {
                let endMarkers = [
                    "Scene description",
                    "Composition",
                    "Characters",
                    "Camera",
                    "Foreground:",
                    "Midground:",
                    "Background:"
                ]
                
                let shouldStop = endMarkers.contains { marker in
                    trimmedLine.contains(marker)
                }
                
                if shouldStop {
                    isCollectingNarration = false
                    continue
                }
                
                // Собираем текст narration
                if !trimmedLine.isEmpty {
                    narrationLines.append(trimmedLine)
                }
            }
        }
        
        // Не забываем последний слайд
        if let lastSlide = currentSlideNumber, !narrationLines.isEmpty {
            let narration = narrationLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !narration.isEmpty {
                result[lastSlide] = cleanupNarrationText(narration)
            }
        }
        
        return result
    }
    
    /// Извлечь номер слайда из заголовка "Slide N" или "Slide N (..."
    private func extractSlideHeader(from line: String) -> Int? {
        let pattern = "^Slide\\s+(\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: range) else {
            return nil
        }
        
        guard let numberRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        
        return Int(String(line[numberRange]))
    }
    
    /// Очистить текст от лишних пробелов и символов
    private func cleanupNarrationText(_ text: String) -> String {
        // Убираем множественные пробелы
        var cleaned = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Убираем пробелы перед знаками препинания
        cleaned = cleaned.replacingOccurrences(of: " ,", with: ",")
        cleaned = cleaned.replacingOccurrences(of: " .", with: ".")
        cleaned = cleaned.replacingOccurrences(of: " !", with: "!")
        cleaned = cleaned.replacingOccurrences(of: " ?", with: "?")
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}