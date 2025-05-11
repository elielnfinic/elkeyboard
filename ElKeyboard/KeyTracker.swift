//
//  KeyTracker.swift
//  ElKeyboard
//
//  Created by Mathe Eliel on 11/05/2025.
//


import Foundation

class KeyTracker {
    // Shared instance for access across app components
    static let shared = KeyTracker()
    
    // App group identifier for sharing data between extension and main app
    private let appGroupIdentifier = "group.com.yourname.ElKeyboard"
    
    // UserDefaults for storing keystroke data
    private let defaults: UserDefaults
    
    // Keys for storing data
    private let totalKeystrokesKey = "totalKeystrokes"
    private let characterCountsKey = "characterCounts"
    
    // Initialize with app group UserDefaults
    init() {
        // Get UserDefaults for the app group
        if let groupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            self.defaults = groupDefaults
        } else {
            // Fall back to standard UserDefaults if app group is not available
            self.defaults = UserDefaults.standard
            print("Warning: App group UserDefaults not available. Data won't be shared.")
        }
    }
    
    // Track a key press
    func trackKeyPress(_ character: String) {
        // Increment total count
        let totalCount = defaults.integer(forKey: totalKeystrokesKey)
        defaults.set(totalCount + 1, forKey: totalKeystrokesKey)
        
        // Update character-specific count
        var characterCounts = defaults.dictionary(forKey: characterCountsKey) as? [String: Int] ?? [:]
        let currentCount = characterCounts[character] ?? 0
        characterCounts[character] = currentCount + 1
        defaults.set(characterCounts, forKey: characterCountsKey)
        
        // Synchronize changes immediately
        defaults.synchronize()
    }
    
    // Get total keystroke count
    func getTotalKeystrokes() -> Int {
        return defaults.integer(forKey: totalKeystrokesKey)
    }
    
    // Get counts for individual characters
    func getCharacterCounts() -> [String: Int] {
        return defaults.dictionary(forKey: characterCountsKey) as? [String: Int] ?? [:]
    }
    
    // Reset all counts
    func resetCounts() {
        defaults.removeObject(forKey: totalKeystrokesKey)
        defaults.removeObject(forKey: characterCountsKey)
        defaults.synchronize()
    }
}