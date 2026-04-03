//
//  About.swift
//  Pulse
//
//  Created by Marcus Raitner on 16.02.26.
//

import SwiftUI

/// App info screen showing the version, feedback links, App Store review button, and photo credits.
struct AboutView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                Image("AppIcon-iOS-Default")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                Text("Pulse")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)
                if let version = UIApplication.appVersion {
                    Text("Version: \(version)")
                        .font(.caption)
                }
                Text("A quick check-in for your mind. Capture your moments, understand your patterns.")
                    .font(.headline)
                    .padding(.top, 10)
                Text("Feedback")
                    .font(Font.title)
                    .padding(.top, 20)
                Text("We are working hard to improve Pulse continuously. Looking forward to your feedback and suggestions. Thanks!")
                Text("👉 Submit issues directly on [GitHub](https://github.com/marcusraitner/pulse/issues)")
                    .padding(.top, 5)
                Text("📧 Or send us an [email](mailto:pulse@raitner.de)")
                Text("And please leave a positive review in the App Store! That means a lot to us.")
                    .bold()
                    .padding(.top, 5)
                HStack {
                    Spacer()
                    Button("Review") {
                        let url = "https://apps.apple.com/app/id6759242390?action=write-review"


                        guard let writeReviewURL = URL(string: url) else {
                            fatalError("Expected a valid URL")
                        }


                        openURL(writeReviewURL)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.vertical)
                    Spacer()
                }
                
                Text("Background images by [Louis Gaudiau](https://unsplash.com/@louisgaudiau), [Kseniia Lobko](https://unsplash.com/@hello_kseniia), [Klara Kulikova](https://unsplash.com/@kkalerry), and [Martin Baron](https://unsplash.com/@elmartinbaron) found on [Unsplash](https://unsplash.com/).")
                    .foregroundStyle(.secondary)
                
                HStack {
                    Spacer()
                    Text("© 2026 Marcus Raitner")
                    Spacer()
                }
            }
            .padding()
        }
    }
}

extension UIApplication {
    /// The app version and build number formatted as `"X.Y.Z (build)"`, or `nil` if either value is missing.
    static var appVersion: String? {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        guard let version, let build else { return nil }
        return "\(version) (\(build))"
    }
}

#Preview {
    AboutView()
}
