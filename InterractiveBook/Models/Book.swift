import Foundation

struct Book: Codable, Identifiable {
    let id: String
    let title: String
    let fileName: String
    var lastPosition: String?
    var currentChapter: String?
    var lastOpened: Date?
    
    init(id: String? = nil, title: String, fileName: String) {
        self.id = id ?? UUID().uuidString
        self.title = title
        self.fileName = fileName
        self.lastOpened = Date()
    }
}

// Прогресс чтения книги
struct BookProgress: Codable {
    let bookId: String
    var currentPosition: String
    var readingTime: TimeInterval
    var choices: [String: String] // Сохраненные выборы игрока
    var lastUpdated: Date
    
    init(bookId: String, position: String = "") {
        self.bookId = bookId
        self.currentPosition = position
        self.readingTime = 0
        self.choices = [:]
        self.lastUpdated = Date()
    }
}
