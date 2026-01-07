import UIKit
import Combine

class DiceRollerViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: DiceRollerViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Формула броска
    private let formulaTextField = UITextField()
    private let rollButton = UIButton(type: .system)
    private let formulaExamplesView = UIStackView()
    
    // Результат броска
    private let resultContainer = UIView()
    private let resultLabel = UILabel()
    private let formulaLabel = UILabel()
    private let diceImageView = UIImageView()
    private let detailsButton = UIButton(type: .system)
    
    // История бросков
    private let historyButton = UIButton(type: .system)
    private let clearHistoryButton = UIButton(type: .system)
    
    // Анализ формулы
    private let analysisView = UIView()
    private let minLabel = UILabel()
    private let maxLabel = UILabel()
    private let avgLabel = UILabel()
    
    // Анимация
    private var isAnimating = false
    private let animationView = UIView()
    private var diceImages: [UIImage] = []
    
    // MARK: - Initialization
    init(viewModel: DiceRollerViewModel = DiceRollerViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(
            title: "Кубики",
            image: UIImage(systemName: "dice"),
            selectedImage: UIImage(systemName: "dice.fill")
        )
        title = "Бросок кубиков"
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
        setupDiceImages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let lastRoll = viewModel.currentRoll {
            updateResultView(with: lastRoll)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        setupScrollView()
        setupFormulaSection()
        setupResultSection()
        setupAnalysisSection()
        setupHistorySection()
        setupAnimationView()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .interactive
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupFormulaSection() {
        let titleLabel = UILabel()
        titleLabel.text = "Формула броска"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        formulaTextField.placeholder = "Например: 2d6+3"
        formulaTextField.text = viewModel.currentFormula
        formulaTextField.borderStyle = .roundedRect
        formulaTextField.font = .systemFont(ofSize: 18, weight: .medium)
        formulaTextField.textAlignment = .center
        formulaTextField.keyboardType = .asciiCapable
        formulaTextField.autocapitalizationType = .none
        formulaTextField.autocorrectionType = .no
        formulaTextField.delegate = self
        formulaTextField.translatesAutoresizingMaskIntoConstraints = false
        
        rollButton.setTitle("БРОСИТЬ", for: .normal)
        rollButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        rollButton.backgroundColor = .systemBlue
        rollButton.tintColor = .white
        rollButton.layer.cornerRadius = 12
        rollButton.addTarget(self, action: #selector(rollButtonTapped), for: .touchUpInside)
        rollButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Быстрые формулы
        let examplesTitle = UILabel()
        examplesTitle.text = "Быстрые формулы:"
        examplesTitle.font = .systemFont(ofSize: 16, weight: .medium)
        examplesTitle.textColor = .secondaryLabel
        
        formulaExamplesView.axis = .horizontal
        formulaExamplesView.spacing = 8
        formulaExamplesView.distribution = .fillEqually
        formulaExamplesView.translatesAutoresizingMaskIntoConstraints = false
        
        for formula in viewModel.recentFormulas.prefix(5) {
            let button = UIButton(type: .system)
            button.setTitle(formula, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            button.backgroundColor = .systemGray6
            button.layer.cornerRadius = 8
            button.addTarget(self, action: #selector(quickFormulaTapped(_:)), for: .touchUpInside)
            formulaExamplesView.addArrangedSubview(button)
        }
        
        [titleLabel, formulaTextField, rollButton, examplesTitle, formulaExamplesView].forEach {
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            formulaTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            formulaTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formulaTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            formulaTextField.heightAnchor.constraint(equalToConstant: 44),
            
            rollButton.topAnchor.constraint(equalTo: formulaTextField.bottomAnchor, constant: 20),
            rollButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rollButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rollButton.heightAnchor.constraint(equalToConstant: 50),
            
            examplesTitle.topAnchor.constraint(equalTo: rollButton.bottomAnchor, constant: 25),
            examplesTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            formulaExamplesView.topAnchor.constraint(equalTo: examplesTitle.bottomAnchor, constant: 8),
            formulaExamplesView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formulaExamplesView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            formulaExamplesView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupResultSection() {
        resultContainer.backgroundColor = .systemGray6
        resultContainer.layer.cornerRadius = 16
        resultContainer.translatesAutoresizingMaskIntoConstraints = false
        
        diceImageView.contentMode = .scaleAspectFit
        diceImageView.translatesAutoresizingMaskIntoConstraints = false
        diceImageView.image = UIImage(systemName: "dice.fill")
        diceImageView.tintColor = .systemBlue
        
        resultLabel.font = .systemFont(ofSize: 48, weight: .bold)
        resultLabel.textAlignment = .center
        resultLabel.text = "–"
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        
        formulaLabel.font = .systemFont(ofSize: 16, weight: .medium)
        formulaLabel.textAlignment = .center
        formulaLabel.textColor = .secondaryLabel
        formulaLabel.text = "Результат броска"
        formulaLabel.translatesAutoresizingMaskIntoConstraints = false
        
        detailsButton.setTitle("Показать детали", for: .normal)
        detailsButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        detailsButton.addTarget(self, action: #selector(showDetails), for: .touchUpInside)
        detailsButton.translatesAutoresizingMaskIntoConstraints = false
        
        [diceImageView, resultLabel, formulaLabel, detailsButton].forEach {
            resultContainer.addSubview($0)
        }
        
        contentView.addSubview(resultContainer)
        
        NSLayoutConstraint.activate([
            resultContainer.topAnchor.constraint(equalTo: formulaExamplesView.bottomAnchor, constant: 30),
            resultContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resultContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            resultContainer.heightAnchor.constraint(equalToConstant: 200),
            
            diceImageView.centerXAnchor.constraint(equalTo: resultContainer.centerXAnchor),
            diceImageView.topAnchor.constraint(equalTo: resultContainer.topAnchor, constant: 20),
            diceImageView.widthAnchor.constraint(equalToConstant: 60),
            diceImageView.heightAnchor.constraint(equalToConstant: 60),
            
            resultLabel.centerXAnchor.constraint(equalTo: resultContainer.centerXAnchor),
            resultLabel.topAnchor.constraint(equalTo: diceImageView.bottomAnchor, constant: 10),
            
            formulaLabel.centerXAnchor.constraint(equalTo: resultContainer.centerXAnchor),
            formulaLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 5),
            
            detailsButton.centerXAnchor.constraint(equalTo: resultContainer.centerXAnchor),
            detailsButton.bottomAnchor.constraint(equalTo: resultContainer.bottomAnchor, constant: -15)
        ])
    }
    
    private func setupAnalysisSection() {
        analysisView.backgroundColor = .systemBackground
        analysisView.layer.cornerRadius = 12
        analysisView.layer.borderWidth = 1
        analysisView.layer.borderColor = UIColor.systemGray4.cgColor
        analysisView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Анализ формулы"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let minTitle = createAnalysisLabel("Минимум:")
        let maxTitle = createAnalysisLabel("Максимум:")
        let avgTitle = createAnalysisLabel("Среднее:")
        
        minLabel.font = .systemFont(ofSize: 16, weight: .medium)
        maxLabel.font = .systemFont(ofSize: 16, weight: .medium)
        avgLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        [minLabel, maxLabel, avgLabel].forEach {
            $0.textAlignment = .right
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let stackView = UIStackView(arrangedSubviews: [
            createAnalysisRow(title: minTitle, value: minLabel),
            createAnalysisRow(title: maxTitle, value: maxLabel),
            createAnalysisRow(title: avgTitle, value: avgLabel)
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, stackView].forEach { analysisView.addSubview($0) }
        contentView.addSubview(analysisView)
        
        NSLayoutConstraint.activate([
            analysisView.topAnchor.constraint(equalTo: resultContainer.bottomAnchor, constant: 25),
            analysisView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            analysisView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            analysisView.heightAnchor.constraint(equalToConstant: 140),
            
            titleLabel.topAnchor.constraint(equalTo: analysisView.topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: analysisView.leadingAnchor, constant: 15),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            stackView.leadingAnchor.constraint(equalTo: analysisView.leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: analysisView.trailingAnchor, constant: -15)
        ])
        
        updateAnalysis()
    }
    
    private func setupHistorySection() {
        let historyContainer = UIView()
        historyContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "История бросков"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        historyButton.setTitle("Показать историю", for: .normal)
        historyButton.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        historyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        historyButton.tintColor = .systemBlue
        historyButton.addTarget(self, action: #selector(showHistory), for: .touchUpInside)
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        
        clearHistoryButton.setTitle("Очистить", for: .normal)
        clearHistoryButton.setImage(UIImage(systemName: "trash"), for: .normal)
        clearHistoryButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        clearHistoryButton.tintColor = .systemRed
        clearHistoryButton.addTarget(self, action: #selector(clearHistory), for: .touchUpInside)
        clearHistoryButton.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, historyButton, clearHistoryButton].forEach {
            historyContainer.addSubview($0)
        }
        
        contentView.addSubview(historyContainer)
        
        NSLayoutConstraint.activate([
            historyContainer.topAnchor.constraint(equalTo: analysisView.bottomAnchor, constant: 25),
            historyContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            historyContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            historyContainer.heightAnchor.constraint(equalToConstant: 60),
            historyContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            
            titleLabel.leadingAnchor.constraint(equalTo: historyContainer.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: historyContainer.centerYAnchor),
            
            clearHistoryButton.trailingAnchor.constraint(equalTo: historyContainer.trailingAnchor),
            clearHistoryButton.centerYAnchor.constraint(equalTo: historyContainer.centerYAnchor),
            
            historyButton.trailingAnchor.constraint(equalTo: clearHistoryButton.leadingAnchor, constant: -15),
            historyButton.centerYAnchor.constraint(equalTo: historyContainer.centerYAnchor)
        ])
    }
    
    private func setupAnimationView() {
        animationView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        animationView.isHidden = true
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        let animatingDice = UIImageView()
        animatingDice.contentMode = .scaleAspectFit
        animatingDice.translatesAutoresizingMaskIntoConstraints = false
        animatingDice.animationImages = diceImages
        animatingDice.animationDuration = 0.5
        animatingDice.animationRepeatCount = 0
        
        animationView.addSubview(animatingDice)
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            animatingDice.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
            animatingDice.centerYAnchor.constraint(equalTo: animationView.centerYAnchor),
            animatingDice.widthAnchor.constraint(equalToConstant: 100),
            animatingDice.heightAnchor.constraint(equalToConstant: 100)
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
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func bindViewModel() {
        viewModel.$currentRoll
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roll in
                if let roll = roll {
                    self?.updateResultView(with: roll)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$isRolling
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRolling in
                self?.handleRollingAnimation(isRolling)
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.showError(error)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$currentFormula
            .receive(on: DispatchQueue.main)
            .sink { [weak self] formula in
                self?.formulaTextField.text = formula
                self?.updateAnalysis()
            }
            .store(in: &cancellables)
    }
    
    private func setupDiceImages() {
        diceImages = (1...6).compactMap {
            UIImage(systemName: "die.face.\($0)")
        }
    }
    
    // MARK: - Helper Methods
    private func createAnalysisLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createAnalysisRow(title: UILabel, value: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [title, value])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }
    
    private func updateResultView(with roll: DiceRoll) {
        resultLabel.text = "\(roll.total)"
        formulaLabel.text = "Бросок: \(roll.formula)"
        
        // Анимируем изменение результата
        UIView.animate(withDuration: 0.3, animations: {
            self.resultLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.resultLabel.transform = .identity
            }
        }
        
        // Показываем детали в консоли
        print("🎲 Бросок \(roll.formula): \(roll.results) = \(roll.total)")
    }
    
    private func updateAnalysis() {
        if let analysis = viewModel.analyzeFormula(viewModel.currentFormula) {
            minLabel.text = "\(analysis.min)"
            maxLabel.text = "\(analysis.max)"
            avgLabel.text = String(format: "%.1f", analysis.average)
        } else {
            minLabel.text = "–"
            maxLabel.text = "–"
            avgLabel.text = "–"
        }
    }
    
    private func handleRollingAnimation(_ isRolling: Bool) {
        if isRolling && !isAnimating {
            isAnimating = true
            animationView.isHidden = false
            
            if let animatingDice = animationView.subviews.first as? UIImageView {
                animatingDice.startAnimating()
            }
            
            // Вибрация
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        } else if !isRolling && isAnimating {
            isAnimating = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animationView.isHidden = true
                if let animatingDice = self.animationView.subviews.first as? UIImageView {
                    animatingDice.stopAnimating()
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func rollButtonTapped() {
        guard let formula = formulaTextField.text, !formula.isEmpty else {
            viewModel.errorMessage = "Введите формулу броска"
            return
        }
        
        viewModel.updateCurrentFormula(formula)
        view.endEditing(true)
        viewModel.rollDice()
    }
    
    @objc private func quickFormulaTapped(_ sender: UIButton) {
        guard let formula = sender.title(for: .normal) else { return }
        formulaTextField.text = formula
        viewModel.updateCurrentFormula(formula)
        viewModel.rollDice(formula: formula)
    }
    
    @objc private func showDetails() {
        guard let roll = viewModel.currentRoll else { return }
        
        let detailsVC = DiceRollDetailsViewController(diceRoll: roll)
        let navController = UINavigationController(rootViewController: detailsVC)
        navController.modalPresentationStyle = .pageSheet
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    @objc private func showHistory() {
        let historyVC = DiceHistoryViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: historyVC)
        navigationController?.pushViewController(historyVC, animated: true)
    }
    
    @objc private func clearHistory() {
        let alert = UIAlertController(
            title: "Очистить историю",
            message: "Вы уверены, что хотите удалить всю историю бросков?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Очистить", style: .destructive) { _ in
            self.viewModel.clearHistory()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension DiceRollerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        rollButtonTapped()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // Проверяем, что вводится допустимая формула
        let allowedCharacters = CharacterSet(charactersIn: "0123456789dD+-")
        let characterSet = CharacterSet(charactersIn: string)
        
        return allowedCharacters.isSuperset(of: characterSet) && updatedText.count <= 20
    }
}
