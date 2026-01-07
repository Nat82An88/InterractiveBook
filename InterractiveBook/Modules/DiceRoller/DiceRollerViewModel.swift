import Foundation
import Combine

class DiceRollerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentFormula: String = "1d20"
    @Published var currentRoll: DiceRoll?
    @Published var rollHistory: [DiceRoll] = []
    @Published var recentFormulas: [String] = ["1d20", "2d6", "1d100", "3d6+3", "1d12+2"]
    @Published var isRolling: Bool = false
    @Published var errorMessage: String?
    @Published var showHistory: Bool = false
    
    // MARK: - Private Properties
    private let diceService: DiceServiceProtocol
    private let storageService: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(diceService: DiceServiceProtocol = DiceService(),
         storageService: StorageServiceProtocol = StorageService()) {
        self.diceService = diceService
        self.storageService = storageService
        loadHistory()
        loadRecentFormulas()
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    func rollDice(formula: String? = nil) {
        let formulaToRoll = formula ?? currentFormula
        
        guard diceService.validateFormula(formulaToRoll) else {
            errorMessage = "Некорректная формула: \(formulaToRoll)"
            return
        }
        
        isRolling = true
        errorMessage = nil
        
        // Анимация броска (симуляция)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let diceRoll = self.diceService.roll(formula: formulaToRoll, context: "Бросок из приложения")
            self.currentRoll = diceRoll
            self.rollHistory.insert(diceRoll, at: 0)
            self.addToRecentFormulas(formulaToRoll)
            self.saveHistory()
            
            self.isRolling = false
            
            // Уведомляем о броске (для синхронизации с книгой)
            NotificationCenter.default.post(
                name: .diceRolled,
                object: nil,
                userInfo: ["diceRoll": diceRoll]
            )
        }
    }
    
    func rollMultiple(formulas: [String]) {
        let rolls = diceService.rollMultiple(formulas: formulas)
        rollHistory.insert(contentsOf: rolls, at: 0)
        saveHistory()
    }
    
    func clearHistory() {
        rollHistory.removeAll()
        saveHistory()
    }
    
    func deleteRoll(at index: Int) {
        guard index < rollHistory.count else { return }
        rollHistory.remove(at: index)
        saveHistory()
    }
    
    func analyzeFormula(_ formula: String) -> (min: Int, max: Int, average: Double)? {
        return diceService.getPossibleRolls(formula: formula)
    }
    
    func updateCurrentFormula(_ formula: String) {
        currentFormula = formula
        // Сохраняем в UserDefaults
        UserDefaults.standard.set(formula, forKey: "lastDiceFormula")
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Подписываемся на запросы бросков из книги
        NotificationCenter.default.publisher(for: .diceRollRequested)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let formula = notification.userInfo?["formula"] as? String {
                    self?.currentFormula = formula
                    self?.rollDice(formula: formula)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadHistory() {
        rollHistory = storageService.loadDiceRolls()
    }
    
    private func saveHistory() {
        do {
            try storageService.saveDiceRolls(rollHistory)
        } catch {
            print("Ошибка сохранения истории бросков: \(error)")
        }
    }
    
    private func loadRecentFormulas() {
        if let savedFormulas = UserDefaults.standard.array(forKey: "recentDiceFormulas") as? [String] {
            recentFormulas = savedFormulas
        }
    }
    
    private func saveRecentFormulas() {
        UserDefaults.standard.set(recentFormulas, forKey: "recentDiceFormulas")
    }
    
    private func addToRecentFormulas(_ formula: String) {
        // Удаляем дубликаты
        recentFormulas.removeAll { $0 == formula }
        
        // Добавляем в начало
        recentFormulas.insert(formula, at: 0)
        
        // Ограничиваем количество
        if recentFormulas.count > 10 {
            recentFormulas = Array(recentFormulas.prefix(10))
        }
        
        saveRecentFormulas()
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let diceRolled = Notification.Name("diceRolled")
}
