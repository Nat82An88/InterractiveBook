import UIKit
import WebKit
import Combine

class EpubReaderViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: ReaderViewModel
    private var webView: WKWebView!
    private var cancellables = Set<AnyCancellable>()
    
    // UI Elements
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    
    // Toolbar Buttons
    private var backButton: UIBarButtonItem!
    private var forwardButton: UIBarButtonItem!
    private var chaptersButton: UIBarButtonItem!
    private var settingsButton: UIBarButtonItem!
    private var diceButton: UIBarButtonItem!
    private var characterButton: UIBarButtonItem!
    
    // MARK: - Initialization
    init(viewModel: ReaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        bindViewModel()
        viewModel.loadBook()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveCurrentPosition()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.cleanup()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = viewModel.bookTitle
        
        setupToolbar()
        setupProgressView()
        setupActivityIndicator()
        setupErrorLabel()
    }
    
    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        progressView.progressTintColor = .systemBlue
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemBlue
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupErrorLabel() {
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.isHidden = true
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.textColor = .systemRed
        errorLabel.font = .systemFont(ofSize: 16, weight: .medium)
        view.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupToolbar() {
        backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        
        forwardButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"),
            style: .plain,
            target: self,
            action: #selector(goForward)
        )
        
        chaptersButton = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: self,
            action: #selector(showChapters)
        )
        
        settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "textformat.size"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        
        diceButton = UIBarButtonItem(
            image: UIImage(systemName: "dice"),
            style: .plain,
            target: self,
            action: #selector(showDiceRoller)
        )
        
        characterButton = UIBarButtonItem(
            image: UIImage(systemName: "person.crop.circle"),
            style: .plain,
            target: self,
            action: #selector(showCharacterSheet)
        )
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbarItems = [
            backButton,
            flexibleSpace,
            forwardButton,
            flexibleSpace,
            chaptersButton,
            flexibleSpace,
            diceButton,
            flexibleSpace,
            characterButton,
            flexibleSpace,
            settingsButton
        ]
        
        navigationController?.isToolbarHidden = false
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        // Настраиваем обработчик сообщений JavaScript
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "bookHandler")
        configuration.userContentController = userContentController
        
        // Дополнительные настройки
        configuration.allowsInlineMediaPlayback = true
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.minimumFontSize = 12
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        view.insertSubview(webView, belowSubview: progressView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Binding
    private func bindViewModel() {
        // Биндинг состояния загрузки
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    self?.progressView.isHidden = false
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.progressView.setProgress(1.0, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.progressView.isHidden = true
                        self?.progressView.progress = 0
                    }
                }
            }
            .store(in: &cancellables)
        
        // Биндинг URL страницы
        viewModel.$currentPageURL
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] url in
                self?.webView.load(URLRequest(url: url))
            }
            .store(in: &cancellables)
        
        // Биндинг ошибок
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage, !errorMessage.isEmpty {
                    self?.showError(message: errorMessage)
                }
            }
            .store(in: &cancellables)
        
        // Биндинг состояния навигации
        viewModel.$canGoBack
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: backButton)
            .store(in: &cancellables)
        
        viewModel.$canGoForward
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: forwardButton)
            .store(in: &cancellables)
        
        // Подписка на уведомления
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDiceRollRequest),
            name: .diceRollRequested,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowCharacterSheet),
            name: .showCharacterSheet,
            object: nil
        )
    }
    
    // MARK: - Actions
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc private func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @objc private func showChapters() {
        let chaptersVC = ChaptersViewController(chapters: viewModel.chapters) { [weak self] chapter in
            self?.viewModel.navigateToChapter(chapter)
            self?.dismiss(animated: true)
        }
        
        let navController = UINavigationController(rootViewController: chaptersVC)
        navController.modalPresentationStyle = .pageSheet
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    @objc private func showSettings() {
        let alert = UIAlertController(title: "Настройки чтения", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Увеличить шрифт", style: .default) { _ in
            self.changeFontSize(increase: true)
        })
        
        alert.addAction(UIAlertAction(title: "Уменьшить шрифт", style: .default) { _ in
            self.changeFontSize(increase: false)
        })
        
        alert.addAction(UIAlertAction(title: "Ночной режим", style: .default) { _ in
            self.toggleNightMode()
        })
        
        alert.addAction(UIAlertAction(title: "Сбросить настройки", style: .destructive) { _ in
            self.resetSettings()
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        // Для iPad
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = settingsButton
        }
        
        present(alert, animated: true)
    }
    
    @objc private func showDiceRoller() {
        NotificationCenter.default.post(
            name: .diceRollRequested,
            object: nil,
            userInfo: ["openDiceRoller": true]
        )
    }
    
    @objc private func showCharacterSheet() {
        NotificationCenter.default.post(
            name: .showCharacterSheet,
            object: nil
        )
    }
    
    @objc private func handleDiceRollRequest(_ notification: Notification) {
        guard let diceRoll = notification.userInfo?["diceRoll"] as? DiceRoll else { return }
        
        // Показываем результат броска в веб-вью
        let script = """
        var diceResult = document.createElement('div');
        diceResult.className = 'dice-result';
        diceResult.innerHTML = '🎲 Бросок: \(diceRoll.formula) = \(diceRoll.total) [\(diceRoll.results.map(String.init).joined(separator: ", "))]';
        diceResult.style.cssText = 'background: #e8f4ff; padding: 10px; margin: 10px 0; border-radius: 8px; border: 2px solid #007AFF;';
        document.body.prepend(diceResult);
        
        // Автоудаление через 5 секунд
        setTimeout(function() {
            diceResult.style.opacity = '0';
            diceResult.style.transition = 'opacity 0.5s';
            setTimeout(function() {
                diceResult.remove();
            }, 500);
        }, 5000);
        """
        
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("Ошибка отображения результата броска: \(error)")
            }
        }
    }
    
    @objc private func handleShowCharacterSheet() {
        // Уведомление будет обработано в TabBarController
    }
    
    // MARK: - Settings Actions
    private func changeFontSize(increase: Bool) {
        let script = """
        var currentSize = parseInt(getComputedStyle(document.body).fontSize);
        var newSize = \(increase ? "currentSize + 2" : "currentSize - 2");
        if (newSize < 12) newSize = 12;
        if (newSize > 30) newSize = 30;
        
        document.body.style.fontSize = newSize + 'px';
        window.epubBridge.setFontSize(newSize);
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func toggleNightMode() {
        let script = """
        window.epubBridge.toggleNightMode();
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func resetSettings() {
        let script = """
        localStorage.removeItem('fontSize');
        localStorage.removeItem('nightMode');
        document.body.style.fontSize = '';
        document.body.classList.remove('night-mode');
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // MARK: - Helper Methods
    private func saveCurrentPosition() {
        let script = """
        window.location.href;
        """
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let urlString = result as? String {
                self?.viewModel.saveProgress(position: urlString)
            }
        }
    }
    
    private func injectCustomCSS() {
        webView.evaluateJavaScript("""
        var style = document.createElement('style');
        style.textContent = `\(Constants.epubCustomCSS)`;
        document.head.appendChild(style);
        """) { _, error in
            if let error = error {
                print("Ошибка инъекции CSS: \(error)")
            }
        }
    }
    
    private func injectJavaScriptBridge() {
        webView.evaluateJavaScript(Constants.javaScriptBridge) { _, error in
            if let error = error {
                print("Ошибка инъекции JavaScript bridge: \(error)")
            } else {
                print("JavaScript bridge успешно внедрен")
            }
        }
    }
    
    private func showError(message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.errorLabel.isHidden = true
        }
    }
}

// MARK: - WKNavigationDelegate
extension EpubReaderViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.setProgress(0.1, animated: true)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        progressView.setProgress(0.5, animated: true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.setProgress(0.9, animated: true)
        
        // Инжектим кастомные стили и JavaScript bridge
        injectCustomCSS()
        injectJavaScriptBridge()
        
        // Обновляем состояние навигации
        viewModel.updateNavigationState(
            canGoBack: webView.canGoBack,
            canGoForward: webView.canGoForward
        )
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(message: "Ошибка загрузки: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(message: "Ошибка загрузки: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        preferences.allowsContentJavaScript = true
        
        // Обрабатываем внешние ссылки
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           url.scheme?.hasPrefix("http") == true {
            
            UIApplication.shared.open(url)
            decisionHandler(.cancel, preferences)
            return
        }
        
        decisionHandler(.allow, preferences)
    }
}

// MARK: - WKUIDelegate
extension EpubReaderViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler
extension EpubReaderViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "bookHandler",
              let body = message.body as? [String: Any] else {
            return
        }
        
        if let action = JavaScriptAction(from: body) {
            viewModel.handleJavaScriptAction(action)
        }
    }
}

// MARK: - ChaptersViewController
class ChaptersViewController: UITableViewController {
    private let chapters: [Chapter]
    private let onChapterSelected: (Chapter) -> Void
    
    init(chapters: [Chapter], onChapterSelected: @escaping (Chapter) -> Void) {
        self.chapters = chapters
        self.onChapterSelected = onChapterSelected
        super.init(style: .insetGrouped)
        title = "Оглавление"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "chapterCell")
        
        if chapters.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "Оглавление недоступно"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .secondaryLabel
            tableView.backgroundView = emptyLabel
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chapters.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chapterCell", for: indexPath)
        let chapter = chapters[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = chapter.title
        config.textProperties.numberOfLines = 2
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chapter = chapters[indexPath.row]
        onChapterSelected(chapter)
    }
}
