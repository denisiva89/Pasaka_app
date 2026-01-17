// PageCurlView.swift
// Обёртка UIPageViewController для SwiftUI с эффектом перелистывания страницы
// ИСПРАВЛЕНО: картинка на весь экран
import SwiftUI
import UIKit

/// PageCurlView - компонент для отображения слайдов с реалистичным эффектом перелистывания страницы
/// Использует встроенный UIPageViewController с transitionStyle .pageCurl
struct PageCurlView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// Массив слайдов для отображения
    let slides: [Slide]
    
    /// Текущий индекс слайда (binding для синхронизации с ViewModel)
    @Binding var currentIndex: Int
    
    /// Callback при смене страницы (для воспроизведения аудио и сохранения прогресса)
    var onPageChanged: ((Int) -> Void)?
    
    /// Ориентация перелистывания (горизонтальная для книжного эффекта)
    var navigationOrientation: UIPageViewController.NavigationOrientation = .horizontal
    
    /// Расположение "корешка" книги (слева - как настоящая книга)
    var spineLocation: UIPageViewController.SpineLocation = .min
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,           // Ключевой параметр - эффект перелистывания!
            navigationOrientation: navigationOrientation,
            options: [.spineLocation: spineLocation.rawValue]
        )
        
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        // Устанавливаем начальную страницу
        if let initialVC = context.coordinator.viewController(for: currentIndex) {
            pageViewController.setViewControllers(
                [initialVC],
                direction: .forward,
                animated: false
            )
        }
        
        // Настраиваем внешний вид
        pageViewController.view.backgroundColor = .black
        
        // Убираем стандартный page indicator (точки внизу)
        for subview in pageViewController.view.subviews {
            if subview is UIPageControl {
                subview.isHidden = true
            }
        }
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        // Обновляем coordinator с новыми данными
        context.coordinator.parent = self
        
        // Проверяем, нужно ли программно перейти на другую страницу
        guard let currentVC = pageViewController.viewControllers?.first,
              let currentVCIndex = currentVC.view.tag as Int?,
              currentVCIndex != currentIndex else {
            return
        }
        
        // Определяем направление анимации
        let direction: UIPageViewController.NavigationDirection = currentIndex > currentVCIndex ? .forward : .reverse
        
        if let newVC = context.coordinator.viewController(for: currentIndex) {
            pageViewController.setViewControllers(
                [newVC],
                direction: direction,
                animated: true
            )
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlView
        
        // Кэш для UIHostingController чтобы избежать пересоздания
        private var viewControllerCache: [Int: UIViewController] = [:]
        
        init(_ parent: PageCurlView) {
            self.parent = parent
        }
        
        // Создаём или возвращаем из кэша ViewController для слайда
        func viewController(for index: Int) -> UIViewController? {
            guard index >= 0 && index < parent.slides.count else {
                return nil
            }
            
            // Проверяем кэш
            if let cached = viewControllerCache[index] {
                return cached
            }
            
            // Создаём новый
            let slide = parent.slides[index]
            let slideView = PageSlideView(slide: slide, index: index, totalSlides: parent.slides.count)
            let hostingController = UIHostingController(rootView: slideView)
            hostingController.view.tag = index
            hostingController.view.backgroundColor = .black
            
            // Сохраняем в кэш
            viewControllerCache[index] = hostingController
            
            return hostingController
        }
        
        // Очищаем кэш при необходимости (например, при смене сказки)
        func clearCache() {
            viewControllerCache.removeAll()
        }
        
        // MARK: - UIPageViewControllerDataSource
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            let index = viewController.view.tag
            return self.viewController(for: index - 1)
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            let index = viewController.view.tag
            return self.viewController(for: index + 1)
        }
        
        // MARK: - UIPageViewControllerDelegate
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let currentVC = pageViewController.viewControllers?.first else {
                return
            }
            
            let newIndex = currentVC.view.tag
            
            // Обновляем binding
            DispatchQueue.main.async {
                self.parent.currentIndex = newIndex
                self.parent.onPageChanged?(newIndex)
            }
        }
        
        // Для двухстраничного режима (опционально, для iPad)
        func pageViewController(
            _ pageViewController: UIPageViewController,
            spineLocationFor orientation: UIInterfaceOrientation
        ) -> UIPageViewController.SpineLocation {
            // Всегда используем одностраничный режим для простоты
            return .min
        }
    }
}

// MARK: - PageSlideView

/// View для отображения отдельного слайда внутри PageCurlView
/// ИСПРАВЛЕНО: картинка на весь экран с .fill
struct PageSlideView: View {
    let slide: Slide
    let index: Int
    let totalSlides: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Чёрный фон на случай если картинка не загрузится
                Color.black
                
                // ИСПРАВЛЕНО: Изображение слайда на ВЕСЬ экран
                BundleImage(name: slide.imageName)
                    .aspectRatio(contentMode: .fill)  // Было .fit, стало .fill
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // Обрезаем края которые выходят за пределы
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#if DEBUG
struct PageCurlView_Previews: PreviewProvider {
    static var previews: some View {
        PageCurlPreviewWrapper()
    }
}

struct PageCurlPreviewWrapper: View {
    @State private var currentIndex = 0
    
    var body: some View {
        PageCurlView(
            slides: [
                Slide(id: "1", imageName: "slide01", audioName: "audio01"),
                Slide(id: "2", imageName: "slide02", audioName: "audio02"),
                Slide(id: "3", imageName: "slide03", audioName: "audio03"),
            ],
            currentIndex: $currentIndex,
            onPageChanged: { index in
                print("Page changed to: \(index)")
            }
        )
    }
}
#endif
