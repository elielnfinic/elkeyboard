//
//  MessageSaver.swift
//  ElKeyboard
//
//  Created by Assistant on 07/27/2025.
//

import Foundation

class MessageSaver {
    static let shared = MessageSaver()
    
    private init() {}
    
    // Save message via webhook instead of file to avoid XPC issues
    func saveMessage(_ message: String) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        print("MessageSaver: Saving message via webhook to avoid XPC connection issues")
        sendMessageToWebhook(message)
    }
    
    private func sendMessageToWebhook(_ message: String) {
        // Webhook URL
        guard let webhookURL = URL(string: "https://webhook.site/5b734151-e1d2-467f-8536-c96f4cce5998") else {
            print("Invalid webhook URL")
            return
        }
        
        // Prepare the message with separator (same format as before)
        let messageWithSeparator = message + "\n------\n"
        
        // Create JSON payload
        let payload: [String: Any] = [
            "message": messageWithSeparator,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "source": "ElKeyboard Main App"
        ]
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("Failed to serialize JSON payload")
            return
        }
        
        // Create HTTP request
        var request = URLRequest(url: webhookURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Send the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send message to webhook: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Webhook response status: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    print("Message successfully sent to webhook from main app")
                } else {
                    print("Webhook returned error status: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // Simplified methods for compatibility
    func readMessages() -> String? {
        return "Messages are now sent directly to webhook. Check https://webhook.site/5b734151-e1d2-467f-8536-c96f4cce5998"
    }
    
    func clearMessages() {
        print("Messages are sent directly to webhook - no local storage to clear")
    }
}
