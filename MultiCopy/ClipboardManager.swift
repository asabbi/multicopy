import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    @Published var history: [ClipboardEntry] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let maxHistorySize = 100
    
    private let pasteboard = NSPasteboard.general
    
    func startMonitoring() {
        lastChangeCount = pasteboard.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.checkForClipboardChanges()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForClipboardChanges() {
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            if let string = pasteboard.string(forType: .string), !string.isEmpty {
                addToHistory(string)
            }
        }
    }
    
    private func addToHistory(_ content: String) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedContent.isEmpty {
            return
        }
        
        if let lastEntry = history.first, lastEntry.content == trimmedContent {
            return
        }
        
        let newEntry = ClipboardEntry(content: trimmedContent)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.history.removeAll { $0.content == trimmedContent }
            self.history.insert(newEntry, at: 0)
            
            if self.history.count > self.maxHistorySize {
                self.history.removeLast()
            }
            
            self.saveHistory()
        }
    }
    
    func copyToClipboard(_ entry: ClipboardEntry) {
        pasteboard.clearContents()
        pasteboard.setString(entry.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
    
    func clearHistory() {
        DispatchQueue.main.async { [weak self] in
            self?.history.removeAll()
            self?.saveHistory()
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "clipboardHistory")
        }
    }
    
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "clipboardHistory"),
           let decodedHistory = try? JSONDecoder().decode([ClipboardEntry].self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.history = decodedHistory
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}