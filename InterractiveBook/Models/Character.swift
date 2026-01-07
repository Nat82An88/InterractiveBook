import Foundation

struct Character: Codable {
    var name: String
    var attributes: [Attribute]
    var skills: [Skill]
    var inventory: [InventoryItem]
    var stats: [String: Int]
    var experience: Int
    
    init(name: String = "Персонаж") {
        self.name = name
        self.attributes = Attribute.defaultAttributes
        self.skills = Skill.defaultSkills
        self.inventory = []
        self.stats = [:]
        self.experience = 0
    }
}

struct Attribute: Codable {
    let name: String
    var value: Int
    var modifier: Int { (value - 10) / 2 }
    
    static let defaultAttributes: [Attribute] = [
        Attribute(name: "Сила", value: 10),
        Attribute(name: "Ловкость", value: 10),
        Attribute(name: "Выносливость", value: 10),
        Attribute(name: "Интеллект", value: 10),
        Attribute(name: "Мудрость", value: 10),
        Attribute(name: "Харизма", value: 10)
    ]
}

struct Skill: Codable {
    let name: String
    var value: Int
    var relatedAttribute: String
    
    static let defaultSkills: [Skill] = [
        Skill(name: "Атлетика", value: 0, relatedAttribute: "Сила"),
        Skill(name: "Акробатика", value: 0, relatedAttribute: "Ловкость"),
        Skill(name: "Магия", value: 0, relatedAttribute: "Интеллект"),
        Skill(name: "Проницательность", value: 0, relatedAttribute: "Мудрость"),
        Skill(name: "Убеждение", value: 0, relatedAttribute: "Харизма")
    ]
}

struct InventoryItem: Codable {
    let id: String
    let name: String
    let description: String
    var quantity: Int
    let weight: Double
}
