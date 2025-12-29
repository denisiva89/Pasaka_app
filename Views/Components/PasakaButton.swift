// PasakaButton.swift - улучшенный контраст и визуальная глубина кнопки
import SwiftUI

struct PasakaButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 40)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.90, green: 0.60, blue: 0.20), // верх — теплее
                                    Color(red: 0.78, green: 0.47, blue: 0.12)  // низ — темнее
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        // Основная мягкая тень вниз (кнопка приподнята)
                        .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 8)
                        // Лёгкая подсветка по краю
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
