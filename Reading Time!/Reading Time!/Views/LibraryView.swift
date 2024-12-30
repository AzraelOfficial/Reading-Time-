import SwiftUI

struct LibraryView: View {
    @State private var books: [Book] = []
    @AppStorage("lastAddedBook") private var lastAddedBook: Date?
    @State private var showingAddBook = false
    
    var body: some View {
        List {
            if books.isEmpty {
                EmptyLibraryView(showingAddBook: $showingAddBook)
            } else {
                ForEach(books) { book in
                    BookRow(book: book)
                        .listRowBackground(
                            isRecentlyAdded(book.dateAdded) ? Color.blue.opacity(0.1) : nil
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                if let index = books.firstIndex(where: { $0.id == book.id }) {
                                    deleteBooks(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("My Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingAddBook = true
                }) {
                    Label("Add Book", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView()
        }
        .onAppear {
            loadBooks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .bookAdded)) { _ in
            loadBooks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .readingProgressUpdated)) { _ in
            loadBooks()
        }
    }
    
    private func loadBooks() {
        books = UserDefaults.standard.books
    }
    
    private func deleteBooks(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
        UserDefaults.standard.books = books
    }
    
    private func isRecentlyAdded(_ date: Date) -> Bool {
        guard let lastAdded = lastAddedBook else { return false }
        return date > lastAdded.addingTimeInterval(-1)
    }
}

// Empty state view
struct EmptyLibraryView: View {
    @Binding var showingAddBook: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Your Library is Empty")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start building your reading collection by adding your first book.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingAddBook = true
            }) {
                Label("Add Your First Book", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 280)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// Enhanced BookRow
struct BookRow: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            // Book Cover
            Group {
                if let coverImageString = book.coverImage,
                   let imageData = Data(base64Encoded: coverImageString),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 60, height: 90)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Book Info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 4)
                            .opacity(0.1)
                            .foregroundColor(.blue)
                        
                        Rectangle()
                            .frame(width: geometry.size.width * progress, height: 4)
                            .foregroundColor(.blue)
                    }
                    .cornerRadius(2)
                }
                .frame(height: 4)
                
                Text("\(book.currentPage) of \(book.totalPages) pages")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var progress: Double {
        Double(book.currentPage) / Double(book.totalPages)
    }
}

// Add the notification name for reading progress updates
extension Notification.Name {
    static let readingProgressUpdated = Notification.Name("readingProgressUpdated")
}

#Preview {
    LibraryView()
} 
