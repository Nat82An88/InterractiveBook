import UIKit

class DiceRollDetailsViewController: UIViewController {
    
    private let diceRoll: DiceRoll
    
    init(diceRoll: DiceRoll) {
        self.diceRoll = diceRoll
        super.init(nibName: nil, bundle: nil)
        title = "Детали броска"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Заголовок
        let titleLabel = UILabel()
        titleLabel.text = "🎲 Бросок кубиков"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        
        // Основной результат
        let resultContainer = UIView()
        resultContainer.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        resultContainer.layer.cornerRadius = 16
        
        let totalLabel = UILabel()
        totalLabel.text = "\(diceRoll.total)"
        totalLabel.font = .systemFont(ofSize: 72, weight: .bold)
        totalLabel.textColor = .systemBlue
        totalLabel.textAlignment = .center
        
        let formulaLabel = UILabel()
        formulaLabel.text = diceRoll.formula
        formulaLabel.font = .systemFont(ofSize: 20, weight: .medium)
        formulaLabel.textAlignment = .center
        formulaLabel.textColor = .secondaryLabel
        
        // Разбивка по кубикам
        let breakdownTitle = UILabel()
        breakdownTitle.text = "Разбивка по кубикам:"
        breakdownTitle.font = .systemFont(ofSize: 18, weight: .semibold)
        
        let breakdownStack = UIStackView()
        breakdownStack.axis = .vertical
        breakdownStack.spacing = 8
        
        for (index, result) in diceRoll.results.enumerated() {
            let row = createBreakdownRow(index: index + 1, result: result)
            breakdownStack.addArrangedSubview(row)
        }
        
        // Итоговая формула
        let sumString = diceRoll.results.map { "\($0)" }.joined(separator: " + ")
        let sumLabel = UILabel()
        sumLabel.text = "Итого: \(sumString) = \(diceRoll.total)"
        sumLabel.font = .systemFont(ofSize: 16, weight: .medium)
        sumLabel.textColor = .systemGreen
        
        // Контекст
        let contextLabel = UILabel()
        contextLabel.text = "Контекст: \(diceRoll.context ?? "Не указан")"
        contextLabel.font = .systemFont(ofSize: 14, weight: .regular)
        contextLabel.textColor = .secondaryLabel
        contextLabel.numberOfLines = 0
        
        // Время
        let timeLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        timeLabel.text = "Время: \(formatter.string(from: diceRoll.timestamp))"
        timeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        timeLabel.textColor = .tertiaryLabel
        
        // Кнопка поделиться
        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Поделиться результатом", for: .normal)
        shareButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        shareButton.backgroundColor = .systemBlue
        shareButton.tintColor = .white
        shareButton.layer.cornerRadius = 12
        shareButton.addTarget(self, action: #selector(shareResult), for: .touchUpInside)
        
        // Добавляем все на экран
        [titleLabel, resultContainer, breakdownTitle, breakdownStack,
         sumLabel, contextLabel, timeLabel, shareButton].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        resultContainer.addSubview(totalLabel)
        resultContainer.addSubview(formulaLabel)
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        formulaLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Констрейнты
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            resultContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            resultContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resultContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            resultContainer.heightAnchor.constraint(equalToConstant: 180),
            
            totalLabel.centerXAnchor.constraint(equalTo: resultContainer.centerXAnchor),
            totalLabel.centerYAnchor.constraint(equalTo: resultContainer.centerYAnchor, constant: -20),
            
            formulaLabel.centerXAnchor.constraint(equalTo: resultContainer.centerXAnchor),
            formulaLabel.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 8),
            
            breakdownTitle.topAnchor.constraint(equalTo: resultContainer.bottomAnchor, constant: 25),
            breakdownTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            breakdownStack.topAnchor.constraint(equalTo: breakdownTitle.bottomAnchor, constant: 12),
            breakdownStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            breakdownStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            sumLabel.topAnchor.constraint(equalTo: breakdownStack.bottomAnchor, constant: 15),
            sumLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            contextLabel.topAnchor.constraint(equalTo: sumLabel.bottomAnchor, constant: 15),
            contextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeLabel.topAnchor.constraint(equalTo: contextLabel.bottomAnchor, constant: 10),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            shareButton.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 25),
            shareButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            shareButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            shareButton.heightAnchor.constraint(equalToConstant: 50),
            shareButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func createBreakdownRow(index: Int, result: Int) -> UIStackView {
        let diceLabel = UILabel()
        diceLabel.text = "🎲 Кубик \(index):"
        diceLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        let resultLabel = UILabel()
        resultLabel.text = "\(result)"
        resultLabel.font = .systemFont(ofSize: 18, weight: .bold)
        resultLabel.textAlignment = .right
        
        let stack = UIStackView(arrangedSubviews: [diceLabel, resultLabel])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        
        return stack
    }
    
    @objc private func shareResult() {
        let resultText = """
        🎲 Результат броска кубиков:
        
        Формула: \(diceRoll.formula)
        Результаты: \(diceRoll.results.map(String.init).joined(separator: ", "))
        Итого: \(diceRoll.total)
        
        Брошено в: \(DateFormatter.localizedString(from: diceRoll.timestamp, dateStyle: .medium, timeStyle: .short))
        
        #ИнтерактивнаяКнига #Кубики
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [resultText],
            applicationActivities: nil
        )
        
        // Для iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
}
