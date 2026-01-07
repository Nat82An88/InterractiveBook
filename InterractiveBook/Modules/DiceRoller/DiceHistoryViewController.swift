import UIKit

class DiceHistoryViewController: UITableViewController {
    
    private let viewModel: DiceRollerViewModel
    
    init(viewModel: DiceRollerViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = "История бросков"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupEmptyState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func setupTableView() {
        tableView.register(DiceRollCell.self, forCellReuseIdentifier: "DiceRollCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupEmptyState() {
        if viewModel.rollHistory.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "История бросков пуста"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.font = .systemFont(ofSize: 18, weight: .medium)
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
    }
    
    @objc private func refreshData() {
        tableView.refreshControl?.endRefreshing()
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rollHistory.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiceRollCell", for: indexPath) as! DiceRollCell
        let roll = viewModel.rollHistory[indexPath.row]
        cell.configure(with: roll)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let roll = viewModel.rollHistory[indexPath.row]
        let detailsVC = DiceRollDetailsViewController(diceRoll: roll)
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.viewModel.deleteRoll(at: indexPath.row)
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
            self?.setupEmptyState()
            completion(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - DiceRollCell
class DiceRollCell: UITableViewCell {
    private let formulaLabel = UILabel()
    private let resultLabel = UILabel()
    private let detailsLabel = UILabel()
    private let timeLabel = UILabel()
    private let diceIcon = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        diceIcon.contentMode = .scaleAspectFit
        diceIcon.tintColor = .systemBlue
        diceIcon.image = UIImage(systemName: "die.face.5")
        
        formulaLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        resultLabel.font = .systemFont(ofSize: 24, weight: .bold)
        resultLabel.textColor = .systemBlue
        
        detailsLabel.font = .systemFont(ofSize: 14, weight: .regular)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.numberOfLines = 0
        
        timeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .tertiaryLabel
        
        let resultStack = UIStackView(arrangedSubviews: [formulaLabel, resultLabel])
        resultStack.axis = .vertical
        resultStack.spacing = 4
        
        let mainStack = UIStackView(arrangedSubviews: [diceIcon, resultStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        
        let containerStack = UIStackView(arrangedSubviews: [mainStack, detailsLabel, timeLabel])
        containerStack.axis = .vertical
        containerStack.spacing = 8
        
        contentView.addSubview(containerStack)
        
        diceIcon.translatesAutoresizingMaskIntoConstraints = false
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            diceIcon.widthAnchor.constraint(equalToConstant: 40),
            diceIcon.heightAnchor.constraint(equalToConstant: 40),
            
            containerStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            containerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with roll: DiceRoll) {
        formulaLabel.text = roll.formula
        resultLabel.text = "\(roll.total)"
        
        let resultsString = roll.results.map { "\($0)" }.joined(separator: " + ")
        detailsLabel.text = "Состав: \(resultsString)"
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        timeLabel.text = formatter.localizedString(for: roll.timestamp, relativeTo: Date())
        
        // Выбираем иконку кубика в зависимости от результата
        let diceNumber = min(max(roll.total % 6, 1), 6)
        diceIcon.image = UIImage(systemName: "die.face.\(diceNumber)")
    }
}
