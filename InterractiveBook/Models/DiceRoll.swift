import Foundation

struct DiceRoll: Codable, Identifiable {
    let id: UUID
    let formula: String
    let results: [Int]
    let total: Int
    let timestamp: Date
    let context: String? // Контекст броска (например, "Бой с гоблином")
    
    init(formula: String, results: [Int], context: String? = nil) {
        self.id = UUID()
        self.formula = formula
        self.results = results
        self.total = results.reduce(0, +)
        self.timestamp = Date()
        self.context = context
    }
}

// Модель для парсинга формулы кубиков
struct DiceFormula {
    let numberOfDice: Int
    let diceSides: Int
    let modifier: Int
    let isNegative: Bool
    
    init?(_ formula: String) {
        let pattern = #"^(\d+)d(\d+)([+-]\d+)?$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(formula.startIndex..., in: formula)
        
        guard let match = regex?.firstMatch(in: formula, range: range),
              let diceCountRange = Range(match.range(at: 1), in: formula),
              let sidesRange = Range(match.range(at: 2), in: formula) else {
            return nil
        }
        
        self.numberOfDice = Int(formula[diceCountRange]) ?? 1
        self.diceSides = Int(formula[sidesRange]) ?? 6
        
        if match.range(at: 3).location != NSNotFound,
           let modifierRange = Range(match.range(at: 3), in: formula) {
            let modifierString = formula[modifierRange]
            self.modifier = Int(modifierString) ?? 0
            self.isNegative = modifierString.hasPrefix("-")
        } else {
            self.modifier = 0
            self.isNegative = false
        }
    }
}
