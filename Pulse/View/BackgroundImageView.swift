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
    @AppStorage(AppStorageKeys.backgroundImageName) private var backgroundImageName: String = "mountain"
    
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage = self.uiImage {
                // use the user's image
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .ignoresSafeArea()
            } else {
                // load the image from assets
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .ignoresSafeArea()
            }
        }
        .onChange(of: backgroundImageData, initial: true) {
            guard let data = backgroundImageData, let uiImage = UIImage(data: data) else {
                uiImage = nil
                return
            }
            
            self.uiImage = uiImage
        }

    }
}

#Preview {
    BackgroundImageView()
}
