import SwiftUI

struct ContentView: View {
    // State to trigger view updates when statistics change
    @State private var totalKeystrokes = 0
    @State private var characterStats: [(character: String, count: Int)] = []
    @State private var showingResetAlert = false
    @State private var name = ""
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Statistics Tab
            NavigationView {
                VStack(spacing: 20) {
                    // Instructions
                    instructionsView
                    
                    // Total keystrokes
                    Text("Total Keystrokes: \(totalKeystrokes)")
                        .font(.headline)
                        .padding()
                    
                    // Character statistics
                    if characterStats.isEmpty {
                        Text("No keystrokes recorded yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        statsListView
                    }
                    
                    Spacer()
                    
                    TextField("Enter some text", text : $name)
                    
                    // Reset button
                    Button(action: {
                        // Show confirmation alert
                        showingResetAlert = true
                    }) {
                        Text("Reset Statistics")
                            .frame(minWidth: 200)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .alert(isPresented: $showingResetAlert) {
                        Alert(
                            title: Text("Reset Statistics"),
                            message: Text("Are you sure you want to reset all keystroke statistics?"),
                            primaryButton: .destructive(Text("Reset")) {
                                resetStats()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding()
                .navigationTitle("ElKeyboard Stats")
                .onAppear {
                    updateStats()
                }
            }
            .tabItem {
                Image(systemName: "chart.bar")
                Text("Statistics")
            }
            .tag(0)
            
            // Messages Tab
            NavigationView {
                VStack(spacing: 20) {
                    // Webhook information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Messages are sent to webhook:")
                            .font(.headline)
                        
                        Link("https://webhook.site/5b734151-e1d2-467f-8536-c96f4cce5998", 
                             destination: URL(string: "https://webhook.site/5b734151-e1d2-467f-8536-c96f4cce5998")!)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                        
                        Text("When you type messages on the keyboard and press return, they are automatically sent to this webhook URL where you can view them in real-time.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to view messages:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("1. Open the webhook URL in your browser")
                        Text("2. Use the ElKeyboard to type messages")
                        Text("3. Press return to complete and send messages")
                        Text("4. View the messages appear on the webhook site")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBlue).opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Message Webhook")
            }
            .tabItem {
                Image(systemName: "network")
                Text("Webhook")
            }
            .tag(1)
        }
    }
    
    // Instructions view
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("To use ElKeyboard:")
                .font(.headline)
            
            Text("1. Go to Settings > General > Keyboard > Keyboards")
            Text("2. Add ElKeyboard")
            Text("3. Allow Full Access for keystroke tracking")
            
            Divider()
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // Statistics list view
    private var statsListView: some View {
        List {
            ForEach(characterStats, id: \.character) { stat in
                HStack {
                    Text(stat.character == " " ? "Space" : stat.character)
                        .font(.system(size: 18))
                        .frame(width: 60, alignment: .leading)
                    
                    Text("\(stat.count) presses")
                    
                    Spacer()
                    
                    // Show percentage
                    if totalKeystrokes > 0 {
                        Text("\(Int((Double(stat.count) / Double(totalKeystrokes)) * 100))%")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // Update statistics
    private func updateStats() {
        // Get current stats from KeyTracker
        totalKeystrokes = KeyTracker.shared.getTotalKeystrokes()
        
        let charCounts = KeyTracker.shared.getCharacterCounts()
        characterStats = charCounts.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 } // Sort by count (descending)
    }
    
    // Reset statistics
    private func resetStats() {
        KeyTracker.shared.resetCounts()
        updateStats()
    }
}
