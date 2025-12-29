import Foundation
import AVFoundation

class AudioService: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var isMuted = false

    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ AudioSession настроена успешно")
        } catch {
            print("❌ Ошибка настройки AudioSession: \(error)")
        }
    }

    func play(audioURL: URL) {
        print("🎵 Попытка воспроизведения: \(audioURL)")
        
        do {
            // Проверяем существование файла
            guard FileManager.default.fileExists(atPath: audioURL.path) else {
                print("❌ Аудио файл не существует: \(audioURL.path)")
                return
            }
            
            // Останавливаем предыдущий плеер
            stop()
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            print("✅ AudioPlayer создан, длительность: \(audioPlayer?.duration ?? 0) сек")

            if !isMuted {
                audioPlayer?.play()
                DispatchQueue.main.async {
                    self.isPlaying = true
                }
                print("✅ Воспроизведение началось")
            } else {
                print("🔇 Звук отключен, воспроизведение пропущено")
            }
        } catch {
            print("❌ Audio play error: \(error)")
        }
    }

    func stop() {
        if audioPlayer != nil {
            print("⏹️ Остановка аудио")
            audioPlayer?.stop()
            audioPlayer = nil
        }

        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }

    func restart() {
        guard let player = audioPlayer else {
            print("❌ Нет активного плеера для restart")
            return
        }

        print("🔄 Перезапуск аудио")
        player.currentTime = 0
        if !isMuted {
            player.play()
            DispatchQueue.main.async {
                self.isPlaying = true
            }
        }
    }

    func toggleMute() {
        isMuted.toggle()
        print("🔇 Mute переключен: \(isMuted)")
        
        if isMuted {
            audioPlayer?.pause()
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        } else {
            audioPlayer?.play()
            DispatchQueue.main.async {
                self.isPlaying = true
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🎵 Аудио завершено, успешно: \(flag)")
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ Ошибка декодирования аудио: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
