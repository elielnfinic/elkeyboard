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
        case "⌫":
            textDocumentProxy.deleteBackward()
        case "return":
            textDocumentProxy.insertText("\n")
        case "123":
            // You could toggle symbol layout here
            break
        default:
            textDocumentProxy.insertText(title)
            keyCount += 1
            sharedDefaults?.set(keyCount, forKey: "totalKeyCount")
        }
    }
}
