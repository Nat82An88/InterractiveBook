import Foundation
import Combine

class ReaderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPageURL: URL?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var bookTitle: String = ""
    @Published var chapters: [Chapter] = []
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var readingProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let book: Book
    private let epubService: EPUBServiceProtocol
    private let storageService: StorageServiceProtocol
    private let diceService: DiceServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var extractedEPUBURL: URL?
    private var bookProgress: BookProgress?
    private var readingTimer: Timer?
    private var startReadingTime: Date?
    
    // MARK: - Initialization
    init(book: Book,
         epubService: EPUBServiceProtocol = EPUBService(),
         storageService: StorageServiceProtocol = StorageService(),
         diceService: DiceServiceProtocol = DiceService()) {
        self.book = book
        self.epubService = epubService
        self.storageService = storageService
        self.diceService = diceService
        self.bookTitle = book.title
        
        loadSavedProgress()
    }
    
    // MARK: - Public Methods
    
    func loadBook() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Загружаем EPUB файл
                let epubURL = try epubService.loadBook(named: book.fileName)
                
                // 2. Распаковываем
                let extractedURL = try epubService.extractEPUB(at: epubURL)
                self.extractedEPUBURL = extractedURL
                
                // 3. Парсим контейнер
                let contentURL = try epubService.parseContainerFile(at: extractedURL)
                
                // 4. Загружаем оглавление
                let chapters = try epubService.getTableOfContents(from: contentURL)
                await MainActor.run {
                    self.chapters = chapters
                }
                
                // 5. Находим первую HTML страницу
                let htmlURL = try epubService.findFirstHTML(in: contentURL)
                
                await MainActor.run {
                    self.currentPageURL = htmlURL
                    self.isLoading = false
                    self.startReadingTimer()
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Ошибка загрузки книги: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveProgress(position: String) {
        if var progress = bookProgress {
            progress.currentPosition = position
            progress.lastUpdated = Date()
            bookProgress = progress
        } else {
            bookProgress = BookProgress(bookId: book.id, position: position)
        }
        
        do {
            if let progress = bookProgress {
                try storageService.saveBookProgress(progress)
            }
        } catch {
            print("Ошибка сохранения прогресса: \(error)")
        }
    }
    
    func handleJavaScriptAction(_ action: JavaScriptAction) {
        switch action {
        case .rollDice(let formula):
            let diceRoll = diceService.roll(formula: formula, context: "Из книги: \(book.title)")
            notifyDiceRoll(diceRoll)
            
        case .showCharacterSheet:
            NotificationCenter.default.post(
                name: .showCharacterSheet,
                object: nil
            )
            
        case .updateCharacter(let stat, let value):
            updateCharacterStat(stat, value: value)
            
        case .saveChoice(let choiceId, let option):
            saveChoice(choiceId: choiceId, option: option)
            
        case .navigateToPage(let urlString):
            if let url = URL(string: urlString) {
                navigateToPage(url)
            }
        }
    }
    
    func navigateToChapter(_ chapter: Chapter) {
        currentPageURL = chapter.url
        saveProgress(position: chapter.url.absoluteString)
    }
    
    func updateNavigationState(canGoBack: Bool, canGoForward: Bool) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
    }
    
    func cleanup() {
        stopReadingTimer()
        if let epubURL = extractedEPUBURL {
            try? FileManager.default.removeItem(at: epubURL)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSavedProgress() {
        bookProgress = storageService.loadBookProgress(bookId: book.id)
    }
    
    private func notifyDiceRoll(_ diceRoll: DiceRoll) {
        NotificationCenter.default.post(
            name: .diceRollRequested,
            object: nil,
            userInfo: ["diceRoll": diceRoll, "formula": diceRoll.formula]
        )
    }
    
    private func updateCharacterStat(_ stat: String, value: Int) {
        if var character = storageService.loadCharacter() {
            character.stats[stat] = value
            try? storageService.saveCharacter(character)
            
            NotificationCenter.default.post(
                name: .characterUpdated,
                object: nil,
                userInfo: ["character": character]
            )
        }
    }
    
    private func saveChoice(choiceId: String, option: String) {
        bookProgress?.choices[choiceId] = option
        if let progress = bookProgress {
            try? storageService.saveBookProgress(progress)
        }
    }
    
    private func navigateToPage(_ url: URL) {
        currentPageURL = url
        saveProgress(position: url.absoluteString)
    }
    
    private func startReadingTimer() {
        stopReadingTimer()
        startReadingTime = Date()
        
        readingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateReadingTime()
        }
    }
    
    private func updateReadingTime() {
        guard let startTime = startReadingTime else { return }
        let elapsedTime = Date().timeIntervalSince(startTime)
        bookProgress?.readingTime += elapsedTime
        startReadingTime = Date()
    }
    
    private func stopReadingTimer() {
        readingTimer?.invalidate()
        readingTimer = nil
        updateReadingTime()
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let diceRollRequested = Notification.Name("diceRollRequested")
    static let showCharacterSheet = Notification.Name("showCharacterSheet")
    static let characterUpdated = Notification.Name("characterUpdated")
}
