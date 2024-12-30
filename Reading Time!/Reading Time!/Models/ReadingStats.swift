import Foundation

struct DailyReadingStats: Codable {
    let date: Date
    let minutesRead: Double
    let progress: Double
}

struct WeeklyReadingStats: Codable {
    let startDate: Date
    let dailyStats: [DailyReadingStats]
    
    var totalMinutes: Double {
        dailyStats.reduce(0) { $0 + $1.minutesRead }
    }
    
    var averageProgress: Double {
        dailyStats.reduce(0.0) { $0 + $1.progress } / Double(dailyStats.count)
    }
} 