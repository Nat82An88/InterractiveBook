import Foundation

enum JavaScriptAction {
    case rollDice(formula: String)
    case showCharacterSheet
    case updateCharacter(stat: String, value: Int)
    case saveChoice(choiceId: String, option: String)
    case navigateToPage(url: String)
    
    init?(from dictionary: [String: Any]) {
        guard let type = dictionary["type"] as? String else { return nil }
        
        switch type {
        case "rollDice":
            if let data = dictionary["data"] as? [String: Any],
               let formula = data["formula"] as? String {
                self = .rollDice(formula: formula)
            } else {
                return nil
            }
            
        case "showCharacterSheet":
            self = .showCharacterSheet
            
        case "updateCharacter":
            if let data = dictionary["data"] as? [String: Any],
               let stat = data["stat"] as? String,
               let value = data["value"] as? Int {
                self = .updateCharacter(stat: stat, value: value)
            } else {
                return nil
            }
            
        case "saveChoice":
            if let data = dictionary["data"] as? [String: Any],
               let choiceId = data["choiceId"] as? String,
               let option = data["option"] as? String {
                self = .saveChoice(choiceId: choiceId, option: option)
            } else {
                return nil
            }
            
        case "navigateToPage":
            if let data = dictionary["data"] as? [String: Any],
               let url = data["url"] as? String {
                self = .navigateToPage(url: url)
            } else {
                return nil
            }
            
        default:
            return nil
        }
    }
}
