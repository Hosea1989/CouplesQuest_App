import Foundation
import SwiftData

/// Daily mood check-in entry with optional journal
@Model
final class MoodEntry {
    /// Unique identifier
    var id: UUID
    
    /// Date of the mood entry
    var date: Date
    
    /// Mood level (1-5): 1 = Rough, 2 = Low, 3 = Okay, 4 = Good, 5 = Great
    var moodLevel: Int
    
    /// Optional journal / reflection text
    var journalText: String?
    
    /// Character ID of the owner
    var ownerID: UUID
    
    init(
        moodLevel: Int,
        journalText: String? = nil,
        ownerID: UUID
    ) {
        self.id = UUID()
        self.date = Date()
        self.moodLevel = moodLevel
        self.journalText = journalText
        self.ownerID = ownerID
    }
    
    /// Emoji representation of the mood level
    var moodEmoji: String {
        switch moodLevel {
        case 1: return "😞"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😄"
        default: return "😐"
        }
    }
    
    /// Display label for the mood level
    var moodLabel: String {
        switch moodLevel {
        case 1: return "Rough"
        case 2: return "Low"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Okay"
        }
    }
    
    /// Whether this entry has a journal note
    var hasJournal: Bool {
        guard let text = journalText else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
