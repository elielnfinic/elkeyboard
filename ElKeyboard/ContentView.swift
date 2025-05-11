import SwiftUI

struct ContentView: View {
    // State to trigger view updates when statistics change
    @State private var totalKeystrokes = 0
    @State private var characterStats: [(character: String, count: Int)] = []
    @State private var showingResetAlert = false
    @State private var name = ""
    
    var body: some View {
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
