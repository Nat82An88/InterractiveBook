import Foundation

protocol DiceServiceProtocol {
    func roll(formula: String, context: String?) -> DiceRoll
    func parseFormula(_ formula: String) -> DiceFormula?
    func rollMultiple(formulas: [String]) -> [DiceRoll]
    func validateFormula(_ formula: String) -> Bool
    func getPossibleRolls(formula: String) -> (min: Int, max: Int, average: Double)?
}

class DiceService: DiceServiceProtocol {
    
    func roll(formula: String, context: String? = nil) -> DiceRoll {
        guard let diceFormula = parseFormula(formula) else {
            // По умолчанию 1d20
            let results = [Int.random(in: 1...20)]
            return DiceRoll(formula: "1d20", results: results, context: context)
        }
        
        var results: [Int] = []
        for _ in 0..<diceFormula.numberOfDice {
            results.append(Int.random(in: 1...diceFormula.diceSides))
        }
        
        let adjustedResults = results.map { diceFormula.isNegative ? $0 - diceFormula.modifier : $0 + diceFormula.modifier }
        
        return DiceRoll(formula: formula, results: adjustedResults, context: context)
    }
    
    func parseFormula(_ formula: String) -> DiceFormula? {
        return DiceFormula(formula)
    }
    
    func rollMultiple(formulas: [String]) -> [DiceRoll] {
        return formulas.map { roll(formula: $0, context: nil) }
    }
    
    // MARK: - Helper Methods
    
    func validateFormula(_ formula: String) -> Bool {
        let pattern = #"^(\d+)d(\d+)([+-]\d+)?$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(formula.startIndex..., in: formula)
        return regex?.firstMatch(in: formula, range: range) != nil
    }
    
    func getPossibleRolls(formula: String) -> (min: Int, max: Int, average: Double)? {
        guard let diceFormula = parseFormula(formula) else { return nil }
        
        let minRoll = diceFormula.numberOfDice + diceFormula.modifier
        let maxRoll = (diceFormula.numberOfDice * diceFormula.diceSides) + diceFormula.modifier
        let average = Double(diceFormula.numberOfDice * (1 + diceFormula.diceSides)) / 2.0 + Double(diceFormula.modifier)
        
        return (minRoll, maxRoll, average)
    }
}
