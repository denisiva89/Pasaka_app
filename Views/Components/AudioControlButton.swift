// AudioControlButton.swift
import SwiftUI

struct AudioControlButton: View {
    var icon: String
    var action: () -> Void
    var isActive: Bool = true

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isActive ? .primary : .gray)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.75))
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                )
        }
    }
}
