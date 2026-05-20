//
//  ExportJSONDocument.swift
//  Pulse
//
//  Created by Marcus Raitner on 20.05.26.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct ExportJSONDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    
    let data: Data
    
    init (data: Data) {
        self.data = data
    }
    
    // We never read, but need to implement that for FileDocument Pr
    init(configuration: ReadConfiguration) throws {
        guard let content = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        
        self.data = content
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
