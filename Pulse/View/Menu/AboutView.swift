//
//  About.swift
//  Pulse
//
//  Created by Marcus Raitner on 16.02.26.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
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
            Text("Pulse is being improved contiously. Looking forward to your feedback and suggestions. Thanks!")
            Text("Submit Issues on [GitHub](https://github.com/marcusraitner/pulse/issues)")
            Text("Contact: [pulse@raitner.de](mailto:pulse@raitner.de)")
            Text("Credits")
                .font(Font.title)
                .padding(.top, 20)
            Text("Background image by \(Text("Kseniia Lobko").bold()) published on [Unsplash](https://unsplash.com/de/fotos/wanderer-uberqueren-bei-sonnenuntergang-schneebedeckte-bergkamme-lJL53PfBYmM)")
            
            Spacer()
            Text("© 2026 Marcus Raitner")
        }
        .padding()
    }
}

extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}

#Preview {
    AboutView()
}
