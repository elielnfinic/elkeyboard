//
//  MessageSaver.swift
//  ElKeyboard
//
//  Created by Assistant on 07/27/2025.
//

import Foundation

class MessageSaver {
    static let shared = MessageSaver()
    
    private let appGroupIdentifier = "group.com.yourcompany.ElKeyboard"
    
    private init() {}
    
    // Save a message to the shared file with separator
    func saveMessage(_ message: String) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Get the shared container directory
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            // Fallback to documents directory for testing
            saveToDocumentsDirectory(message)
            return
        }
        
        let messagesFileURL = containerURL.appendingPathComponent("messages.txt")
        saveToFileURL(messagesFileURL, message: message)
    }
    
    // Fallback method for testing when app group is not available
    private func saveToDocumentsDirectory(_ message: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let messagesFileURL = documentsDirectory.appendingPathComponent("messages.txt")
        saveToFileURL(messagesFileURL, message: message)
    }
    
    private func saveToFileURL(_ fileURL: URL, message: String) {
        // Prepare the message with separator
        let messageWithSeparator = message + "\n------\n"
        
        // Write to file (append if exists, create if doesn't)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // File exists, append to it
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                if let data = messageWithSeparator.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        } else {
            // File doesn't exist, create it
            try? messageWithSeparator.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    // Method to read messages for testing
    func readMessages() -> String? {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let messagesFileURL = containerURL.appendingPathComponent("messages.txt")
            return try? String(contentsOf: messagesFileURL, encoding: .utf8)
        } else {
            // Fallback to documents directory for testing
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let messagesFileURL = documentsDirectory.appendingPathComponent("messages.txt")
            return try? String(contentsOf: messagesFileURL, encoding: .utf8)
        }
    }
    
    // Method to clear messages for testing
    func clearMessages() {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let messagesFileURL = containerURL.appendingPathComponent("messages.txt")
            try? FileManager.default.removeItem(at: messagesFileURL)
        } else {
            // Fallback to documents directory for testing
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let messagesFileURL = documentsDirectory.appendingPathComponent("messages.txt")
            try? FileManager.default.removeItem(at: messagesFileURL)
        }
    }
}