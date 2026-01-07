import Foundation

protocol StorageServiceProtocol {
    func save<T: Codable>(_ object: T, forKey key: String) throws
    func load<T: Codable>(forKey key: String) throws -> T?
    func delete(forKey key: String) throws
    func saveBookProgress(_ progress: BookProgress) throws
    func loadBookProgress(bookId: String) -> BookProgress?
    func saveCharacter(_ character: Character) throws
    func loadCharacter() -> Character?
    func saveDiceRolls(_ rolls: [DiceRoll]) throws
    func loadDiceRolls() -> [DiceRoll]
}

class StorageService: StorageServiceProtocol {
    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    
    init(userDefaults: UserDefaults = .standard,
         fileManager: FileManager = .default) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
    }
    
    // MARK: - Generic Methods
    
    func save<T: Codable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(object)
        userDefaults.set(data, forKey: key)
    }
    
    func load<T: Codable>(forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
    
    func delete(forKey key: String) throws {
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - Book Progress
    
    func saveBookProgress(_ progress: BookProgress) throws {
        let key = "book_progress_\(progress.bookId)"
        try save(progress, forKey: key)
    }
    
    func loadBookProgress(bookId: String) -> BookProgress? {
        let key = "book_progress_\(bookId)"
        return try? load(forKey: key)
    }
    
    // MARK: - Character
    
    func saveCharacter(_ character: Character) throws {
        try save(character, forKey: "current_character")
    }
    
    func loadCharacter() -> Character? {
        return try? load(forKey: "current_character")
    }
    
    // MARK: - Dice Rolls History
    
    func saveDiceRolls(_ rolls: [DiceRoll]) throws {
        try save(rolls, forKey: "dice_rolls_history")
    }
    
    func loadDiceRolls() -> [DiceRoll] {
        return (try? load(forKey: "dice_rolls_history")) ?? []
    }
    
    // MARK: - Auto-save
    
    func autoSave<T: Codable>(_ object: T, forKey key: String, interval: TimeInterval = 30) {
        // Реализация автосохранения может использовать Timer
        // или сохранять при переходе в бэкграунд
    }
}
