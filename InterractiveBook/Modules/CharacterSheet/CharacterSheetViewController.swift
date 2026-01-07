import UIKit
import Combine

class CharacterSheetViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: CharacterSheetViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerView = UIView()
    private let nameLabel = UILabel()
    private let editButton = UIButton(type: .system)
    
    private let attributesSection = UIView()
    private let inventorySection = UIView()
    private let statsSection = UIView()
    private let experienceSection = UIView()
    
    // MARK: - Initialization
    init(viewModel: CharacterSheetViewModel = CharacterSheetViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(
            title: "Персонаж",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
        title = "Лист персонажа"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        setupScrollView()
        setupHeader()
        setupAttributesSection()
        setupStatsSection()
        setupExperienceSection()
        setupInventorySection()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.backgroundColor = .systemGray6
        headerView.layer.cornerRadius = 12
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        editButton.tintColor = .systemBlue
        editButton.addTarget(self, action: #selector(toggleEditMode), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        
        [nameLabel, editButton].forEach { headerView.addSubview($0) }
        contentView.addSubview(headerView)
    }
    
    private func setupAttributesSection() {
        attributesSection.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Характеристики"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let attributesStack = UIStackView()
        attributesStack.axis = .vertical
        attributesStack.spacing = 12
        attributesStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Создаем строки для характеристик
        for attribute in viewModel.character.attributes {
            let attributeRow = createAttributeRow(attribute)
            attributesStack.addArrangedSubview(attributeRow)
        }
        
        [titleLabel, attributesStack].forEach { attributesSection.addSubview($0) }
        contentView.addSubview(attributesSection)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: attributesSection.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: attributesSection.leadingAnchor),
            
            attributesStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            attributesStack.leadingAnchor.constraint(equalTo: attributesSection.leadingAnchor),
            attributesStack.trailingAnchor.constraint(equalTo: attributesSection.trailingAnchor),
            attributesStack.bottomAnchor.constraint(equalTo: attributesSection.bottomAnchor)
        ])
    }
    
    private func setupStatsSection() {
        statsSection.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Показатели"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let statsGrid = createStatsGrid()
        statsGrid.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, statsGrid].forEach { statsSection.addSubview($0) }
        contentView.addSubview(statsSection)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: statsSection.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: statsSection.leadingAnchor),
            
            statsGrid.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            statsGrid.leadingAnchor.constraint(equalTo: statsSection.leadingAnchor),
            statsGrid.trailingAnchor.constraint(equalTo: statsSection.trailingAnchor),
            statsGrid.bottomAnchor.constraint(equalTo: statsSection.bottomAnchor)
        ])
    }
    
    private func setupExperienceSection() {
        experienceSection.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Опыт и уровни"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let expLabel = UILabel()
        expLabel.font = .systemFont(ofSize: 16, weight: .medium)
        expLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, expLabel, progressView].forEach { experienceSection.addSubview($0) }
        contentView.addSubview(experienceSection)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: experienceSection.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: experienceSection.leadingAnchor),
            
            expLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            expLabel.leadingAnchor.constraint(equalTo: experienceSection.leadingAnchor),
            
            progressView.topAnchor.constraint(equalTo: expLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: experienceSection.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: experienceSection.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: experienceSection.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    private func setupInventorySection() {
        inventorySection.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Инвентарь"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        addButton.setTitle(" Добавить", for: .normal)
        addButton.tintColor = .systemBlue
        addButton.addTarget(self, action: #selector(addInventoryItem), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        let inventoryTableView = UITableView()
        inventoryTableView.register(InventoryCell.self, forCellReuseIdentifier: "InventoryCell")
        inventoryTableView.dataSource = self
        inventoryTableView.delegate = self
        inventoryTableView.rowHeight = UITableView.automaticDimension
        inventoryTableView.estimatedRowHeight = 60
        inventoryTableView.isScrollEnabled = false
        inventoryTableView.translatesAutoresizingMaskIntoConstraints = false
        
        let weightLabel = UILabel()
        weightLabel.font = .systemFont(ofSize: 14, weight: .medium)
        weightLabel.textColor = .secondaryLabel
        weightLabel.textAlignment = .right
        weightLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, addButton, inventoryTableView, weightLabel].forEach { inventorySection.addSubview($0) }
        contentView.addSubview(inventorySection)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: inventorySection.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: inventorySection.leadingAnchor),
            
            addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: inventorySection.trailingAnchor),
            
            inventoryTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            inventoryTableView.leadingAnchor.constraint(equalTo: inventorySection.leadingAnchor),
            inventoryTableView.trailingAnchor.constraint(equalTo: inventorySection.trailingAnchor),
            inventoryTableView.heightAnchor.constraint(equalToConstant: 200),
            
            weightLabel.topAnchor.constraint(equalTo: inventoryTableView.bottomAnchor, constant: 8),
            weightLabel.trailingAnchor.constraint(equalTo: inventorySection.trailingAnchor),
            weightLabel.bottomAnchor.constraint(equalTo: inventorySection.bottomAnchor)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -20),
            
            editButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            editButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -15),
            
            attributesSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 25),
            attributesSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            attributesSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            statsSection.topAnchor.constraint(equalTo: attributesSection.bottomAnchor, constant: 25),
            statsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            experienceSection.topAnchor.constraint(equalTo: statsSection.bottomAnchor, constant: 25),
            experienceSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            experienceSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            inventorySection.topAnchor.constraint(equalTo: experienceSection.bottomAnchor, constant: 25),
            inventorySection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            inventorySection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            inventorySection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func bindViewModel() {
        viewModel.$character
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
        
        viewModel.$isEditing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEditing in
                self?.updateEditMode(isEditing)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Creation Helpers
    private func createAttributeRow(_ attribute: Attribute) -> UIStackView {
        let nameLabel = UILabel()
        nameLabel.text = attribute.name
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let valueLabel = UILabel()
        valueLabel.text = "\(attribute.value)"
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textAlignment = .center
        valueLabel.textColor = .systemBlue
        valueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        let modifierLabel = UILabel()
        modifierLabel.text = attribute.modifier >= 0 ? "+\(attribute.modifier)" : "\(attribute.modifier)"
        modifierLabel.font = .systemFont(ofSize: 16, weight: .medium)
        modifierLabel.textColor = .systemGreen
        modifierLabel.textAlignment = .center
        modifierLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        let stepper = UIStepper()
        stepper.value = Double(attribute.value)
        stepper.minimumValue = 1
        stepper.maximumValue = 30
        stepper.isHidden = !viewModel.isEditing
        stepper.tag = viewModel.character.attributes.firstIndex(where: { $0.name == attribute.name }) ?? 0
        stepper.addTarget(self, action: #selector(attributeStepperChanged(_:)), for: .valueChanged)
        
        let valueStack = UIStackView(arrangedSubviews: [valueLabel, modifierLabel])
        valueStack.axis = .vertical
        valueStack.spacing = 4
        valueStack.alignment = .center
        
        let stack = UIStackView(arrangedSubviews: [nameLabel, valueStack, stepper])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.distribution = .fill
        
        return stack
    }
    
    private func createStatsGrid() -> UIStackView {
        let stats = viewModel.character.stats
        let statKeys = ["Уровень", "Здоровье", "Броня", "Инициатива", "Пассивная внимательность"]
        
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 12
        
        for key in statKeys {
            let value = stats[key] ?? 0
            let row = createStatRow(name: key, value: value)
            grid.addArrangedSubview(row)
        }
        
        return grid
    }
    
    private func createStatRow(name: String, value: Int) -> UIStackView {
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .secondaryLabel
        
        let valueLabel = UILabel()
        valueLabel.text = "\(value)"
        valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        valueLabel.textAlignment = .right
        
        let stack = UIStackView(arrangedSubviews: [nameLabel, valueLabel])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        
        return stack
    }
    
    // MARK: - Actions
    @objc private func toggleEditMode() {
        if viewModel.isEditing {
            viewModel.saveCharacter()
        } else {
            viewModel.isEditing = true
        }
    }
    
    @objc private func attributeStepperChanged(_ sender: UIStepper) {
        let index = sender.tag
        let attribute = viewModel.editedAttributes[index]
        viewModel.updateAttribute(attribute.name, newValue: Int(sender.value))
        
        // Обновляем отображение
        if let attributesStack = attributesSection.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            let row = attributesStack.arrangedSubviews[index] as? UIStackView
            if let valueStack = row?.arrangedSubviews[1] as? UIStackView,
               let valueLabel = valueStack.arrangedSubviews[0] as? UILabel,
               let modifierLabel = valueStack.arrangedSubviews[1] as? UILabel {
                
                valueLabel.text = "\(Int(sender.value))"
                let modifier = (Int(sender.value) - 10) / 2
                modifierLabel.text = modifier >= 0 ? "+\(modifier)" : "\(modifier)"
            }
        }
    }
    
    @objc private func addInventoryItem() {
        let alert = UIAlertController(title: "Добавить предмет", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Название предмета"
            textField.text = self.viewModel.newItemName
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Описание (необязательно)"
            textField.text = self.viewModel.newItemDescription
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Количество"
            textField.keyboardType = .numberPad
            textField.text = self.viewModel.newItemQuantity
        }
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Добавить", style: .default) { _ in
            let name = alert.textFields?[0].text ?? ""
            let description = alert.textFields?[1].text ?? ""
            let quantity = alert.textFields?[2].text ?? "1"
            
            self.viewModel.newItemName = name
            self.viewModel.newItemDescription = description
            self.viewModel.newItemQuantity = quantity
            self.viewModel.addInventoryItem()
            
            self.updateInventorySection()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Update Methods
    private func updateUI() {
        nameLabel.text = viewModel.character.name
        
        // Обновляем характеристики
        updateAttributesSection()
        
        // Обновляем показатели
        updateStatsSection()
        
        // Обновляем опыт
        updateExperienceSection()
        
        // Обновляем инвентарь
        updateInventorySection()
    }
    
    private func updateEditMode(_ isEditing: Bool) {
        editButton.setImage(UIImage(systemName: isEditing ? "checkmark" : "pencil"), for: .normal)
        
        // Показываем/скрываем степперы для характеристик
        if let attributesStack = attributesSection.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            for (index, row) in attributesStack.arrangedSubviews.enumerated() {
                if let stack = row as? UIStackView,
                   let stepper = stack.arrangedSubviews.last as? UIStepper {
                    stepper.isHidden = !isEditing
                    stepper.value = Double(viewModel.editedAttributes[index].value)
                }
            }
        }
        
        // Разрешаем редактирование имени
        if isEditing {
            let alert = UIAlertController(title: "Изменить имя", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = self.viewModel.character.name
                textField.placeholder = "Имя персонажа"
            }
            
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in
                self.viewModel.cancelEditing()
            })
            
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { _ in
                if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                    self.viewModel.editedName = newName
                    self.nameLabel.text = newName
                }
            })
            
            present(alert, animated: true)
        }
    }
    
    private func updateAttributesSection() {
        // Очищаем старые представления
        if let attributesStack = attributesSection.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            attributesStack.removeFromSuperview()
        }
        
        // Создаем новые строки характеристик
        let attributesStack = UIStackView()
        attributesStack.axis = .vertical
        attributesStack.spacing = 12
        attributesStack.translatesAutoresizingMaskIntoConstraints = false
        
        for attribute in viewModel.editedAttributes {
            let attributeRow = createAttributeRow(attribute)
            attributesStack.addArrangedSubview(attributeRow)
        }
        
        // Добавляем заголовок, если его нет
        if attributesSection.subviews.isEmpty {
            let titleLabel = UILabel()
            titleLabel.text = "Характеристики"
            titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            attributesSection.addSubview(titleLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: attributesSection.topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: attributesSection.leadingAnchor)
            ])
        }
        
        attributesSection.addSubview(attributesStack)
        
        NSLayoutConstraint.activate([
            attributesStack.topAnchor.constraint(equalTo: attributesSection.subviews[0].bottomAnchor, constant: 12),
            attributesStack.leadingAnchor.constraint(equalTo: attributesSection.leadingAnchor),
            attributesStack.trailingAnchor.constraint(equalTo: attributesSection.trailingAnchor),
            attributesStack.bottomAnchor.constraint(equalTo: attributesSection.bottomAnchor)
        ])
    }
    
    private func updateStatsSection() {
        // Обновляем значения в статистике
        if let statsGrid = statsSection.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            let statKeys = ["Уровень", "Здоровье", "Броня", "Инициатива", "Пассивная внимательность"]
            
            for (index, row) in statsGrid.arrangedSubviews.enumerated() {
                if let stack = row as? UIStackView,
                   let valueLabel = stack.arrangedSubviews.last as? UILabel {
                    let key = statKeys[index]
                    let value = viewModel.character.stats[key] ?? 0
                    valueLabel.text = "\(value)"
                }
            }
        }
    }
    
    private func updateExperienceSection() {
        guard experienceSection.subviews.count >= 3 else { return }
        
        let expLabel = experienceSection.subviews[1] as? UILabel
        let progressView = experienceSection.subviews[2] as? UIProgressView
        
        expLabel?.text = "Опыт: \(viewModel.character.experience) / \(viewModel.experienceToNextLevel)"
        progressView?.progress = Float(viewModel.progressToNextLevel)
        progressView?.progressTintColor = .systemBlue
    }
    
    private func updateInventorySection() {
        // Обновляем таблицу
        if let tableView = inventorySection.subviews.first(where: { $0 is UITableView }) as? UITableView {
            tableView.reloadData()
            
            // Обновляем высоту таблицы
            let height = CGFloat(viewModel.inventoryItems.count * 60) + 44
            tableView.constraints.first(where: { $0.firstAttribute == .height })?.constant = min(height, 300)
        }
        
        // Обновляем вес
        if let weightLabel = inventorySection.subviews.last as? UILabel {
            weightLabel.text = String(format: "Общий вес: %.1f кг", viewModel.totalWeight)
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension CharacterSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.inventoryItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InventoryCell", for: indexPath) as! InventoryCell
        let item = viewModel.inventoryItems[indexPath.row]
        cell.configure(with: item)
        
        cell.onQuantityChanged = { [weak self] newQuantity in
            self?.viewModel.updateInventoryItemQuantity(at: indexPath.row, newQuantity: newQuantity)
            self?.updateInventorySection()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.viewModel.removeInventoryItem(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self?.updateInventorySection()
            completion(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - InventoryCell
class InventoryCell: UITableViewCell {
    var onQuantityChanged: ((Int) -> Void)?
    
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let quantityLabel = UILabel()
    private let stepper = UIStepper()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.numberOfLines = 1
        
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        
        quantityLabel.font = .systemFont(ofSize: 18, weight: .bold)
        quantityLabel.textAlignment = .center
        quantityLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        stepper.minimumValue = 0
        stepper.maximumValue = 999
        stepper.stepValue = 1
        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        
        let quantityStack = UIStackView(arrangedSubviews: [quantityLabel, stepper])
        quantityStack.axis = .horizontal
        quantityStack.spacing = 8
        quantityStack.alignment = .center
        
        let textStack = UIStackView(arrangedSubviews: [nameLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let mainStack = UIStackView(arrangedSubviews: [textStack, quantityStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 16
        mainStack.alignment = .center
        mainStack.distribution = .fill
        
        contentView.addSubview(mainStack)
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with item: InventoryItem) {
        nameLabel.text = item.name
        descriptionLabel.text = item.description.isEmpty ? "Без описания" : item.description
        quantityLabel.text = "×\(item.quantity)"
        stepper.value = Double(item.quantity)
    }
    
    @objc private func stepperChanged() {
        let newQuantity = Int(stepper.value)
        quantityLabel.text = "×\(newQuantity)"
        onQuantityChanged?(newQuantity)
    }
}
