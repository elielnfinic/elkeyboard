//
//  KeyboardViewController.swift
//  ElKeyboard
//
//  Created by Mathe Eliel on 11/05/2025.
//


import UIKit

class KeyboardViewController: UIInputViewController {
    
    // Our custom keyboard view
    private var keyboardView: KeyboardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up keyboard view
        setupKeyboardView()
    }
    
    private func setupKeyboardView() {
        // Create keyboard view with frame matching the input view's bounds
        keyboardView = KeyboardView(frame: view.bounds)
        keyboardView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Set key press handler
        keyboardView.keyPressHandler = { [weak self] character in
            // Insert the character
            self?.textDocumentProxy.insertText(character)
            
            // Track the key press
            KeyTracker.shared.trackKeyPress(character)
        }
        
        // Add keyboard view to the input view
        view.addSubview(keyboardView)
    }
    
    // This is called when the keyboard is about to appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardView.setupKeys()
    }
    
    // Handle next keyboard button press
    override func handleInputModeList(from view: UIView, with event: UIEvent) {
        // Pass the event to the superclass to switch between keyboards
        super.handleInputModeList(from: view, with: event)
    }
}