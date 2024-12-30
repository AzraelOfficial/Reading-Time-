import Foundation

struct UserProfile: Codable {
    var id: String
    var username: String
    var dailyReadingGoal: TimeInterval // in minutes
    var preferredLanguage: String
    var joinDate: Date
} 