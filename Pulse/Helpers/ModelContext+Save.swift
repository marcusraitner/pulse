//
//  ModelContext+Save.swift
//  Pulse
//
//  Created by Marcus Raitner on 27.03.26.
//

import OSLog
import Foundation
import SwiftData

extension ModelContext {
    /// Attempts to save the context, logging an error on failure.
    /// - Parameters:
    ///   - message: A description of the operation, prepended to the error message.
    ///   - logger: The `Logger` instance to use for error reporting.
    func saveOrLog(_ message: String, logger: Logger) {
        do {
            try save()
        } catch {
            logger.error("\(message) \(String(describing: error))")
        }
    }
}
