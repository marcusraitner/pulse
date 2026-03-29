//
//  BackgroundImageView.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.03.26.
//

import SwiftUI

/// Full-screen background image view. Displays a custom image from `AppStorage` when set,
/// or falls back to the built-in mountain artwork. Applies a slight brightness adjustment in dark mode.
struct BackgroundImageView: View {
    @AppStorage(AppStorageKeys.backgroundImageData) private var backgroundImageData: Data?
    
    @State private var uiImage: UIImage?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let uiImage = self.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .brightness(colorScheme == .dark ? -0.2 : 0.0)
                    .ignoresSafeArea()
            } else {
                Image(colorScheme == .dark ? "mountain-dark" : "mountain")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .brightness(colorScheme == .dark ? 0.0 : -0.1)
                    .ignoresSafeArea()
            }
        }
        .onChange(of: backgroundImageData, initial: true) {
            if let data = backgroundImageData {
                if let uiImage = UIImage(data: data) {
                    self.uiImage = uiImage
                }
            } else {
                self.uiImage = nil
            }
        }

    }
}

#Preview {
    BackgroundImageView()
}
