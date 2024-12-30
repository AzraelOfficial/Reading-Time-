import SwiftUI

struct BookSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBook: Book?
    @State private var books: [Book] = []
    @State private var showingAddBook = false
    
    var body: some View {
        List {
            ForEach(books) { book in
                Button(action: {
                    selectedBook = book
                    dismiss()
                }) {
                    BookSelectionRow(book: book)
                }
            }
        }
        .navigationTitle("Select a Book")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadBooks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .bookAdded)) { _ in
            loadBooks()
        }
    }
    
    private func loadBooks() {
        books = UserDefaults.standard.books
    }
}

// Update BookRow to be more compact for selection
struct BookSelectionRow: View {
    let book: Book
    
    var body: some View {
        HStack {
            // Book Cover
            if let coverImageString = book.coverImage,
               let imageData = Data(base64Encoded: coverImageString),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 60)
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 60)
            }
            
            // Book Details
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
} 