import Foundation
import Combine

class CharacterSheetViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var character: Character
    @Published var isEditing = false
    @Published var editedName: String = ""
    @Published var editedAttributes: [Attribute] = []
    @Published var showAttributeEditor = false
    @Published var selectedAttribute: Attribute?
    @Published var inventoryItems: [InventoryItem] = []
    @Published var newItemName: String = ""
    @Published var newItemDescription: String = ""
    @Published var newItemQuantity: String = "1"
    
    // MARK: - Private Properties
    private let storageService: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(storageService: StorageServiceProtocol = StorageService()) {
        self.storageService = storageService
        
        // Загружаем персонажа или создаем нового
        if let savedCharacter = storageService.loadCharacter() {
            self.character = savedCharacter
        } else {
            self.character = Character(name: "Искатель приключений")
        }
        
        self.editedName = character.name
        self.editedAttributes = character.attributes
        self.inventoryItems = character.inventory
        
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    func saveCharacter() {
        character.name = editedName
        character.attributes = editedAttributes
        character.inventory = inventoryItems
        
        do {
            try storageService.saveCharacter(character)
            isEditing = false
            
            // Уведомляем об обновлении персонажа
            NotificationCenter.default.post(
                name: .characterUpdated,
                object: nil,
                userInfo: ["character": character]
            )
            
        } catch {
            print("Ошибка сохранения персонажа: \(error)")
        }
    }
    
    func cancelEditing() {
        editedName = character.name
        editedAttributes = character.attributes
        isEditing = false
    }
    
    func updateAttribute(_ attributeName: String, newValue: Int) {
        guard var index = editedAttributes.firstIndex(where: { $0.name == attributeName }) else { return }
        
        // Ограничиваем значения
        let clampedValue = min(max(newValue, 1), 30)
        editedAttributes[index].value = clampedValue
    }
    
    func addExperience(_ amount: Int) {
        character.experience += amount
        saveCharacter()
    }
    
    func updateStat(_ statName: String, value: Int) {
        character.stats[statName] = value
        saveCharacter()
    }
    
    func addInventoryItem() {
        guard !newItemName.isEmpty else { return }
        
        let item = InventoryItem(
            id: UUID().uuidString,
            name: newItemName,
            description: newItemDescription,
            quantity: Int(newItemQuantity) ?? 1,
            weight: 0.0
        )
        
        inventoryItems.append(item)
        newItemName = ""
        newItemDescription = ""
        newItemQuantity = "1"
    }
    
    func removeInventoryItem(at index: Int) {
        guard index < inventoryItems.count else { return }
        inventoryItems.remove(at: index)
    }
    
    func updateInventoryItemQuantity(at index: Int, newQuantity: Int) {
        guard index < inventoryItems.count else { return }
        inventoryItems[index].quantity = max(0, newQuantity)
    }
    
    func calculateTotalWeight() -> Double {
        return inventoryItems.reduce(0.0) { $0 + ($1.weight * Double($1.quantity)) }
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Подписываемся на обновления из книги
        NotificationCenter.default.publisher(for: .characterUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let updatedCharacter = notification.userInfo?["character"] as? Character {
                    self?.character = updatedCharacter
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    var totalWeight: Double {
        calculateTotalWeight()
    }
    
    var experienceToNextLevel: Int {
        // Простая формула для уровней
        let currentLevel = character.stats["level"] ?? 1
        return currentLevel * 1000
    }
    
    var progressToNextLevel: Double {
        let needed = experienceToNextLevel
        guard needed > 0 else { return 0 }
        return Double(character.experience) / Double(needed)
    }
}
