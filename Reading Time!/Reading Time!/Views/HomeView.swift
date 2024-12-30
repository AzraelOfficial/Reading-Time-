import SwiftUI

struct HomeView: View {
    @AppStorage("dailyGoal") private var dailyGoal: Double = 30 {
        didSet {
            // Update progress whenever daily goal changes
            updateProgress()
        }
    }
    @AppStorage("dailyProgress") private var progress: Double = 0.0
    @AppStorage("lastResetDate") private var lastResetDate = Date()
    @AppStorage("dailyReadingTime") private var dailyReadingTime: TimeInterval = 0
    @State private var isReadingTimerActive = false
    @State private var readingTime: TimeInterval = 0
    @State private var showingPageInputDialog = false
    @State private var showingBookSelection = false
    @State private var currentPage = ""
    @State private var selectedBook: Book?
    @State private var books: [Book] = []
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            // Daily Goal Progress Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)
                    Text("Daily Goal")
                        .font(.title3.bold())
                    Spacer()
                    Text("\(Int(dailyReadingTime/60))/\(Int(dailyGoal)) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Progress Bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 24)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: calculateProgressWidth(), height: 24)
                        .animation(.spring(duration: 0.5), value: progress)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            
            // Current Book Section
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    Text("Current Book")
                        .font(.title3.bold())
                    Spacer()
                    Button(action: { showingBookSelection = true }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                    }
                }
                
                if let book = selectedBook {
                    HStack(spacing: 16) {
                        // Book Cover
                        if let coverImageString = book.coverImage,
                           let imageData = Data(base64Encoded: coverImageString),
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 70, height: 100)
                                .cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 70, height: 100)
                        }
                        
                        // Book Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                                .lineLimit(2)
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Page \(book.currentPage) of \(book.totalPages)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                } else {
                    Button(action: { showingBookSelection = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Select a Book")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            
            // Reading Timer
            VStack(spacing: 16) {
                Text(timeString(from: dailyReadingTime))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                HStack(spacing: 24) {
                    // Start/Pause Button
                    Button(action: isReadingTimerActive ? pauseReading : startReading) {
                        Image(systemName: isReadingTimerActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(isReadingTimerActive ? .orange : .green)
                    }
                    
                    // Stop Button
                    Button(action: { showingPageInputDialog = true }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.red)
                    }
                    .disabled(!isReadingTimerActive)
                    .opacity(isReadingTimerActive ? 1 : 0.5)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reading Time")
        .onAppear {
            checkAndResetProgress()
            loadBooks()
            // Ensure progress is correct when view appears
            updateProgress()
        }
        .onReceive(timer) { _ in
            if isReadingTimerActive {
                readingTime += 1
                dailyReadingTime += 1
                updateProgress()
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            checkAndResetProgress()
        }
        .sheet(isPresented: $showingBookSelection) {
            BookSelectionView(selectedBook: $selectedBook)
        }
        .alert("Update Reading Progress", isPresented: $showingPageInputDialog) {
            TextField("Current Page", text: $currentPage)
                .keyboardType(.numberPad)
            Button("Cancel") {
                cancelReading()
            }
            Button("Save") {
                saveReadingProgress()
            }
        } message: {
            if let book = selectedBook {
                Text("Enter the page number you reached in '\(book.title)'")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .bookAdded)) { _ in
            loadBooks()
        }
    }
    
    private func startReading() {
        isReadingTimerActive = true
        if let book = selectedBook {
            currentPage = String(book.currentPage)
        }
    }
    
    private func pauseReading() {
        isReadingTimerActive = false
    }
    
    private func saveReadingProgress() {
        guard let pageNumber = Int(currentPage),
              let bookIndex = books.firstIndex(where: { $0.id == selectedBook?.id }) else {
            return
        }
        
        // Update the book's current page
        books[bookIndex].currentPage = pageNumber
        selectedBook?.currentPage = pageNumber
        
        // Save updated books to UserDefaults
        UserDefaults.standard.books = books
        
        // Post notification for reading progress update
        NotificationCenter.default.post(name: .readingProgressUpdated, object: nil)
        
        // Add current session time to daily total
        dailyReadingTime += readingTime
        
        // Save reading session
        let session = ReadingSession(
            bookId: books[bookIndex].id,
            duration: readingTime,
            date: Date()
        )
        saveReadingSession(session)
        
        // Only reset the session timer
        isReadingTimerActive = false
        readingTime = 0
    }
    
    private func cancelReading() {
        isReadingTimerActive = false
        readingTime = 0
    }
    
    private func loadBooks() {
        books = UserDefaults.standard.books
        if selectedBook == nil && !books.isEmpty {
            selectedBook = books.first
        }
    }
    
    private func saveReadingSession(_ session: ReadingSession) {
        var sessions = UserDefaults.standard.readingSessions
        sessions.append(session)
        UserDefaults.standard.readingSessions = sessions
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func checkAndResetProgress() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we're in a new day
        if !calendar.isDate(lastResetDate, inSameDayAs: now) {
            // If the last reset was yesterday or earlier, reset progress
            progress = 0.0
            dailyReadingTime = 0
            lastResetDate = calendar.startOfDay(for: now)
            
            // Post notification for stats update
            NotificationCenter.default.post(name: .dailyProgressReset, object: nil)
        }
    }
    
    private func calculateProgressWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 48 // Adjust for padding
        return screenWidth * progress
    }
    
    private func updateProgress() {
        // Calculate progress based on current daily reading time and goal
        progress = min(dailyReadingTime / (dailyGoal * 60), 1.0)
    }
}

// Add this extension to handle reading sessions storage
extension UserDefaults {
    var readingSessions: [ReadingSession] {
        get {
            guard let data = data(forKey: "readingSessions"),
                  let sessions = try? JSONDecoder().decode([ReadingSession].self, from: data) else {
                return []
            }
            return sessions
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            set(data, forKey: "readingSessions")
        }
    }
}

struct ReadingSession: Codable {
    let bookId: UUID
    let duration: TimeInterval
    let date: Date
    
    init(bookId: UUID, duration: TimeInterval, date: Date = Date()) {
        self.bookId = bookId
        self.duration = duration
        self.date = date
    }
}

// Add notification for daily progress reset
extension Notification.Name {
    static let dailyProgressReset = Notification.Name("dailyProgressReset")
} 