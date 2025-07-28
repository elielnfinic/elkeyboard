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
    
    // UserDefaults for storing keystroke data (using standard to avoid XPC issues)
    private let defaults: UserDefaults
    
    // Keys for storing data with ElKeyboard prefix to avoid conflicts
    private let totalKeystrokesKey = "ElKeyboard_totalKeystrokes"
    private let characterCountsKey = "ElKeyboard_characterCounts"
    
    // Initialize with standard UserDefaults to avoid XPC connection issues
    init() {
        self.defaults = UserDefaults.standard
        print("KeyTracker: Using standard UserDefaults to avoid XPC connection issues")
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