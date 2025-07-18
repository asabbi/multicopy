import Foundation

struct ClipboardEntry: Codable, Identifiable {
    let id: UUID
    let content: String
    let timestamp: Date
    let preview: String
    
    init(content: String) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.preview = ClipboardEntry.createPreview(from: content)
    }
    
    private static func createPreview(from content: String) -> String {
        let maxLength = 80
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        
        if cleaned.count > maxLength {
            let endIndex = cleaned.index(cleaned.startIndex, offsetBy: maxLength)
            return String(cleaned[..<endIndex]) + "..."
        }
        
        return cleaned
    }
    
    var displayText: String {
        return preview.isEmpty ? "(Empty)" : preview
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}