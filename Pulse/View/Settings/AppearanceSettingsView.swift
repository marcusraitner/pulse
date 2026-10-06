//
//  AppearanceSettingsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 14.02.26.
//  Copyright © 2026 de.raitner. All rights reserved.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AppearanceSettingsView: View {

    @AppStorage(AppStorageKeys.backgroundImageData) private var backgroundImageData: Data?
    @AppStorage(AppStorageKeys.backgroundImageName) private var backgroundImageName: String = "mountain"
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "traffic"

    @State private var backgroundImageSelection: PhotosPickerItem?
    // Decoded when the stored photo changes, not on every body pass
    @State private var backgroundImage: Image?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Image(systemName: "paintbrush.fill")
                        .titleLabelIcon(.blue)
                    Text("Appearance")
                        .font(.title2.bold())
                        .padding(.top, 4)
                    Text("Customize the overall appearance here.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Picker(selection: $themeName) {
                    ForEach(Theme.builtIn) { theme in
                        ThemePreview(theme)
                            .tag(theme.id)
                    }
                } label: {
                    Text("Theme: ")
                }
                .pickerStyle(.navigationLink)

                let columns: [GridItem] = [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]

                VStack(alignment: .leading, spacing: 8) {
                    Text("Background Image")
                        .font(.headline)
                    Text("Select a custom background image. Darker backgrounds work best.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)


                    LazyVGrid(columns: columns, spacing: 8) {
                        let presets = ["mountain", "mountain-dark", "clouds", "moon", "stars",
                                       "fuji", "overland", "ridges", "embers"]

                        ForEach(presets, id: \.self) { imageName in
                            Image("\(imageName)-thumb")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipped()
                                .contentShape(Rectangle())
                                .cornerRadius(12)
                                .onTapGesture {
                                    backgroundImageName = imageName
                                    backgroundImageData = nil
                                }
                                .overlay(alignment: .bottomTrailing) {
                                    if imageName == backgroundImageName && backgroundImageData == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, .blue)
                                            .padding(8)
                                    }
                                }
                        }

                        PhotosPicker(selection: $backgroundImageSelection, matching: .images, photoLibrary: .shared()) {
                            if let backgroundImage {
                                backgroundImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipped()
                                    .contentShape(Rectangle())
                                    .cornerRadius(12)
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, .blue)
                                            .padding(8)
                                    }
                            } else {
                                Image("mountain")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipped()
                                    .contentShape(Rectangle())
                                    .cornerRadius(12)
                                    .saturation(0.2)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .imageScale(.large)
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 2)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: backgroundImageData, initial: true) {
            backgroundImage = backgroundImageData.flatMap { UIImage(data: $0) }.map { Image(uiImage: $0) }
        }
        .onChange(of: backgroundImageSelection) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    backgroundImageData = data
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}
