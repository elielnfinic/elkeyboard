//
//  KeyboardView.swift
//  ElKeyboard
//
//  Created by Mathe Eliel on 11/05/2025.
//


import UIKit

class KeyboardView: UIView {
    // Callback for key presses
    var keyPressHandler: ((String) -> Void)?
    
    // Keys for our simple keyboard
    private let keys = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]
    
    // Color theme
    private let keyColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    private let specialKeyColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    private let keyboardBackgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = keyboardBackgroundColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // Set up the keyboard UI
    func setupKeys() {
        // Remove any existing keys
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        // Calculate key sizes based on view width
        let keyWidth = bounds.width / 10
        let keyHeight: CGFloat = 50
        let spacing: CGFloat = 2
        
        // Add letter keys
        for (rowIndex, row) in keys.enumerated() {
            let rowOffset = (10 - CGFloat(row.count)) * keyWidth / 2
            
            for (keyIndex, key) in row.enumerated() {
                let keyButton = createKeyButton(
                    withTitle: key,
                    frame: CGRect(
                        x: rowOffset + CGFloat(keyIndex) * keyWidth,
                        y: CGFloat(rowIndex) * (keyHeight + spacing),
                        width: keyWidth - spacing,
                        height: keyHeight
                    ),
                    backgroundColor: keyColor
                )
                addSubview(keyButton)
            }
        }
        
        // Add special keys (space, delete, return, numbers)
        let bottomRowY = CGFloat(keys.count) * (keyHeight + spacing)
        
        // Delete key
        let deleteButton = createKeyButton(
            withTitle: "⌫",
            frame: CGRect(
                x: bounds.width - keyWidth * 2 + spacing,
                y: bottomRowY,
                width: keyWidth * 2 - spacing * 2,
                height: keyHeight
            ),
            backgroundColor: specialKeyColor
        )
        addSubview(deleteButton)
        
        // Space key
        let spaceButton = createKeyButton(
            withTitle: "space",
            frame: CGRect(
                x: keyWidth * 2,
                y: bottomRowY,
                width: bounds.width - keyWidth * 4,
                height: keyHeight
            ),
            backgroundColor: keyColor
        )
        addSubview(spaceButton)
        
        // Return key
        let returnButton = createKeyButton(
            withTitle: "return",
            frame: CGRect(
                x: 0,
                y: bottomRowY,
                width: keyWidth * 2 - spacing,
                height: keyHeight
            ),
            backgroundColor: specialKeyColor
        )
        addSubview(returnButton)
        
        // Add "next keyboard" button (globe icon)
        let nextKeyboardButton = UIButton(type: .system)
        nextKeyboardButton.frame = CGRect(
            x: 0,
            y: bottomRowY + keyHeight + spacing,
            width: keyWidth * 2,
            height: keyHeight
        )
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        nextKeyboardButton.backgroundColor = specialKeyColor
        nextKeyboardButton.layer.cornerRadius = 5
        nextKeyboardButton.addTarget(self, action: #selector(nextKeyboardTapped), for: .touchUpInside)
        addSubview(nextKeyboardButton)
    }
    
    // Create a single key button
    private func createKeyButton(withTitle title: String, frame: CGRect, backgroundColor: UIColor) -> UIButton {
        let button = UIButton(frame: frame)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 5
        button.setTitleColor(.black, for: .normal)
        
        // Set the title based on key type
        switch title {
        case "space":
            button.setTitle("Space", for: .normal)
        case "delete":
            button.setTitle("⌫", for: .normal)
        case "return":
            button.setTitle("↵", for: .normal)
        default:
            button.setTitle(title, for: .normal)
        }
        
        // Add action for the button
        button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        
        // Store the actual key value
        button.accessibilityIdentifier = title
        
        return button
    }
    
    // Handle key press events
    @objc private func keyPressed(_ sender: UIButton) {
        guard let key = sender.accessibilityIdentifier else { return }
        
        // Add visual feedback
        let originalColor = sender.backgroundColor
        sender.backgroundColor = UIColor(white: 0.8, alpha: 1.0)
        
        // Restore original color after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sender.backgroundColor = originalColor
        }
        
        // Determine what character to insert
        var insertText = key
        
        switch key {
        case "space":
            insertText = " "
        case "delete":
            // Special handling for delete key
            keyPressHandler?("\u{8}") // Backspace character
            return
        case "return":
            insertText = "\n"
        default:
            break
        }
        
        // Call the handler with the character
        keyPressHandler?(insertText)
    }
    
    // Handle next keyboard button
    @objc private func nextKeyboardTapped() {
        let inputVC = next as? UIInputViewController
        inputVC?.advanceToNextInputMode()
    }
}
