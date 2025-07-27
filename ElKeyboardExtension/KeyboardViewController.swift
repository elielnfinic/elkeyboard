import UIKit

class KeyboardViewController: UIInputViewController {
    
    let rows: [[String]] = [
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L"],
        ["Z","X","C","V","B","N","M"],
        ["123", "space", "⌫", "return"]
    ]
    
    let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.ElKeyboard") // Replace with your group
    var keyCount = 0
    var currentMessage = "" // Track the current message being typed
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray5
        setupKeyboard()
    }
    
    func setupKeyboard() {
        let keyboardStack = UIStackView()
        keyboardStack.axis = .vertical
        keyboardStack.spacing = 8
        keyboardStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardStack)
        
        NSLayoutConstraint.activate([
            keyboardStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            keyboardStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            keyboardStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            keyboardStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
        ])
        
        for rowKeys in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.distribution = .fillEqually
            
            for key in rowKeys {
                let button = createButton(title: key)
                row.addArrangedSubview(button)
            }
            keyboardStack.addArrangedSubview(row)
        }
    }
    
    func createButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title.uppercased(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.backgroundColor = .white
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        return button
    }
    
    @objc func keyPressed(_ sender: UIButton) {
        guard let title = sender.title(for: .normal)?.lowercased() else { return }
        
        switch title {
        case "space":
            textDocumentProxy.insertText(" ")
            currentMessage += " "
        case "⌫":
            textDocumentProxy.deleteBackward()
            if !currentMessage.isEmpty {
                currentMessage.removeLast()
            }
        case "return":
            textDocumentProxy.insertText("\n")
            // Message is complete, save it to file (don't add \n to currentMessage)
            saveMessageToFile()
            currentMessage = "" // Reset for next message
        case "123":
            // You could toggle symbol layout here
            break
        default:
            textDocumentProxy.insertText(title)
            currentMessage += title
            keyCount += 1
            sharedDefaults?.set(keyCount, forKey: "totalKeyCount")
        }
    }
    
    // Save the completed message to a file with separator
    private func saveMessageToFile() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Get the shared container directory
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourcompany.ElKeyboard") else {
            print("Unable to access shared container for app group: group.com.yourcompany.ElKeyboard")
            print("This is likely due to missing entitlements. Messages will not be saved.")
            print("To fix this, ensure both the main app and keyboard extension have proper app group entitlements.")
            return
        }
        
        let messagesFileURL = containerURL.appendingPathComponent("messages.txt")
        
        // Prepare the message with separator
        let messageWithSeparator = currentMessage + "\n------\n"
        
        // Write to file (append if exists, create if doesn't)
        if FileManager.default.fileExists(atPath: messagesFileURL.path) {
            // File exists, append to it
            if let fileHandle = try? FileHandle(forWritingTo: messagesFileURL) {
                fileHandle.seekToEndOfFile()
                if let data = messageWithSeparator.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        } else {
            // File doesn't exist, create it
            do {
                try messageWithSeparator.write(to: messagesFileURL, atomically: true, encoding: .utf8)
                print("Successfully created messages file and saved message")
            } catch {
                print("Failed to create messages file: \(error)")
            }
        }
    }
}
