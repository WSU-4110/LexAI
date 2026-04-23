//
//  ThinkingBubbleView.swift
//  LexAI_iOS
//
//  Created by Hassan Alkhafaji on 4/13/26.
//
import SwiftUI

/// Shows a 3-dot typing indicator while LexAI is generating a reply.
/// Uses staggered `.easeInOut` animations on three circles that repeat indefinitely.
struct ThinkingBubbleView: View {
    /// Toggles the pulsing dots and is set to `true` in `onAppear`.
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .opacity(animating ? 1.0 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer(minLength: 48)
        }
        .onAppear { animating = true }
    }
}
