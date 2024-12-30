import SwiftUI
import Charts
import AuthenticationServices

struct AccountView: View {
    @AppStorage("dailyGoal") private var dailyGoal: Double = 30
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("userID") private var userID = ""
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @State private var weeklyStats: WeeklyReadingStats = WeeklyReadingStats(
        startDate: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
        dailyStats: []
    )
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        List {
            if isSignedIn {
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(userName)
                                .font(.title2)
                            if !userEmail.isEmpty {
                                Text(userEmail)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                Section {
                    WeeklyProgressChart(weeklyStats: weeklyStats)
                        .listRowInsets(EdgeInsets())
                        .frame(height: 300)
                        .padding(.vertical)
                } header: {
                    Text("Weekly Progress")
                }
                .listRowBackground(Color.clear)
                
                Section("Reading History") {
                    ForEach(weeklyStats.dailyStats.reversed(), id: \.date) { stat in
                        DailyReadingRow(stat: stat, goal: dailyGoal)
                    }
                }
                
                Section("Statistics") {
                    StatRow(title: "Total Reading Time", 
                           value: "\(Int(weeklyStats.totalMinutes)) minutes")
                    StatRow(title: "Daily Average", 
                           value: "\(Int(weeklyStats.totalMinutes / 7)) min/day")
                    StatRow(title: "Goal Achievement", 
                           value: "\(calculateGoalAchievement())%")
                    StatRow(title: "Best Day", 
                           value: getBestDay())
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        signOut()
                    }
                }
            } else {
                Section {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task {
                                await handleSignInWithApple(result)
                            }
                        }
                    )
                    .frame(height: 50)
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Account")
        .onAppear {
            loadWeeklyStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dailyProgressReset)) { _ in
            loadWeeklyStats()
        }
    }
    
    private func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Handle successful sign in
                userID = appleIDCredential.user
                
                // Get user name if available
                if let fullName = appleIDCredential.fullName {
                    userName = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                }
                
                // Get email if available
                if let email = appleIDCredential.email {
                    userEmail = email
                }
                
                // Set signed in state
                isSignedIn = true
                
                print("Successfully signed in with Apple ID: \(userID)")
            }
            
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
            // Handle sign in error
            isSignedIn = false
            userID = ""
            userName = ""
            userEmail = ""
        }
    }
    
    private func signOut() {
        isSignedIn = false
        userID = ""
        userName = ""
        userEmail = ""
    }
    
    private func calculateGoalAchievement() -> Int {
        let daysAchieved = weeklyStats.dailyStats.filter { $0.minutesRead >= dailyGoal }.count
        return Int((Double(daysAchieved) / Double(weeklyStats.dailyStats.count)) * 100)
    }
    
    private func getBestDay() -> String {
        guard let best = weeklyStats.dailyStats.max(by: { $0.minutesRead < $1.minutesRead }) else {
            return "N/A"
        }
        return "\(Int(best.minutesRead)) min"
    }
    
    private func loadWeeklyStats() {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        
        // Load actual reading sessions from UserDefaults
        let sessions = UserDefaults.standard.readingSessions
        
        let dailyStats = (0...6).map { days in
            let date = calendar.date(byAdding: .day, value: days, to: weekStart)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Filter sessions for this day
            let dayMinutes = sessions
                .filter { $0.date >= dayStart && $0.date < dayEnd }
                .reduce(0.0) { $0 + ($1.duration / 60.0) }
            
            return DailyReadingStats(
                date: date,
                minutesRead: dayMinutes,
                progress: min(dayMinutes / dailyGoal, 1.0)
            )
        }
        
        weeklyStats = WeeklyReadingStats(
            startDate: weekStart,
            dailyStats: dailyStats
        )
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct WeeklyProgressChart: View {
    let weeklyStats: WeeklyReadingStats
    @AppStorage("dailyGoal") private var dailyGoal: Double = 30
    
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let gradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .bottom,
        endPoint: .top
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
            
            Chart {
                ForEach(weeklyStats.dailyStats.sorted(by: { $0.date < $1.date }), id: \.date) { stat in
                    BarMark(
                        x: .value("Day", weekDays[Calendar.current.component(.weekday, from: stat.date) - 1]),
                        y: .value("Minutes", stat.minutesRead)
                    )
                    .foregroundStyle(gradient)
                    .cornerRadius(4)
                }
                
                RuleMark(
                    y: .value("Daily Goal", dailyGoal)
                )
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .foregroundStyle(.red)
                .annotation(position: .leading) {
                    Text("Goal")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(preset: .aligned) { value in
                    AxisValueLabel(centered: true) {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text("\(Int(minutes))m")
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Legend and total
            HStack {
                // Reading time indicator
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(gradient)
                        .frame(width: 12, height: 12)
                    Text("Reading Time")
                        .font(.caption)
                }
                
                // Goal line indicator
                HStack(spacing: 4) {
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundColor(.red)
                        .frame(width: 12, height: 1)
                    Text("Daily Goal")
                        .font(.caption)
                }
                
                Spacer()
                
                Text("Total: \(Int(weeklyStats.totalMinutes))m")
                    .font(.caption.bold())
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct DailyReadingRow: View {
    let stat: DailyReadingStats
    let goal: Double
    
    var body: some View {
        HStack {
            Text(formattedDate)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(stat.minutesRead)) minutes")
                    .font(.subheadline)
                
                ProgressView(value: stat.progress)
                    .frame(width: 100)
                    .tint(stat.minutesRead >= goal ? .green : .blue)
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: stat.date)
    }
} 