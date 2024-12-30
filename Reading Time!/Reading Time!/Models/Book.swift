import Foundation

struct Book: Identifiable, Codable {
    let id: UUID
    let title: String
    let author: String
    var coverImage: String?
    var currentPage: Int
    var totalPages: Int
    var notes: [Note]
    var dateAdded: Date
    
    struct Note: Identifiable, Codable {
        let id: UUID
        let content: String
        let date: Date
    }
    
    init(id: UUID = UUID(), title: String, author: String, coverImage: String? = nil, 
         currentPage: Int = 0, totalPages: Int, notes: [Note] = [], dateAdded: Date = Date()) {
        self.id = id
        self.title = title
        self.author = author
        self.coverImage = coverImage
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.notes = notes
        self.dateAdded = dateAdded
    }
} 