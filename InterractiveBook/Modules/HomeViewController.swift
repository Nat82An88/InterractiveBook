import UIKit

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "Интерактивная книга"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        
        let openButton = UIButton(type: .system)
        openButton.setTitle("Открыть книгу", for: .normal)
        openButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        openButton.addTarget(self, action: #selector(openEpubReader), for: .touchUpInside)
        openButton.backgroundColor = .systemBlue
        openButton.setTitleColor(.white, for: .normal)
        openButton.layer.cornerRadius = 10
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, openButton])
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.alignment = .center
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            openButton.widthAnchor.constraint(equalToConstant: 200),
            openButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func openEpubReader() {
        let epubVC = EpubReaderViewController()
        navigationController?.pushViewController(epubVC, animated: true)
    }
}
