//
//  ElKeyboardTests.swift
//  ElKeyboardTests
//
//  Created by Mathe Eliel on 10/05/2025.
//

import Testing
@testable import ElKeyboard

struct ElKeyboardTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testMessageTracking() async throws {
        // Test that KeyTracker can track key presses
        let tracker = KeyTracker.shared
        
        // Reset to start fresh
        tracker.resetCounts()
        
        // Track some characters
        tracker.trackKeyPress("h")
        tracker.trackKeyPress("e")
        tracker.trackKeyPress("l")
        tracker.trackKeyPress("l")
        tracker.trackKeyPress("o")
        
        // Verify total count
        #expect(tracker.getTotalKeystrokes() == 5)
        
        // Verify character counts
        let counts = tracker.getCharacterCounts()
        #expect(counts["l"] == 2)
        #expect(counts["h"] == 1)
        #expect(counts["e"] == 1)
        #expect(counts["o"] == 1)
    }
    
    @Test func testMessageSaving() async throws {
        // Test that messages are saved with proper separator
        let messageSaver = MessageSaver.shared
        
        // Clear any existing messages
        messageSaver.clearMessages()
        
        // Save a test message
        messageSaver.saveMessage("Hello World")
        
        // Verify the message was saved with separator
        let savedContent = messageSaver.readMessages()
        #expect(savedContent == "Hello World\n------\n")
        
        // Save another message
        messageSaver.saveMessage("Second Message")
        
        // Verify both messages are saved with separators
        let updatedContent = messageSaver.readMessages()
        #expect(updatedContent == "Hello World\n------\nSecond Message\n------\n")
        
        // Clean up
        messageSaver.clearMessages()
    }

}
