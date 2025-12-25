import UIKit
import WebKit
import Zip

class EpubReaderViewController: UIViewController {
    
    // MARK: - Properties
    private var webView: WKWebView!
    private var epubPath: String?
    private var bookTitle: String = ""
    
    // UI Elements
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        loadEpub()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveReadingProgress()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure navigation
        navigationItem.title = bookTitle.isEmpty ? "Читатель EPUB" : bookTitle
        setupToolbar()
        
        // Add progress view
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        view.addSubview(progressView)
        
        // Add activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Constraints for progress view
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupToolbar() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        
        let forwardButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"),
            style: .plain,
            target: self,
            action: #selector(goForward)
        )
        
        let chapterButton = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: self,
            action: #selector(showChapters)
        )
        
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "textformat.size"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        
        toolbarItems = [
            backButton,
            flexibleSpace,
            forwardButton,
            flexibleSpace,
            chapterButton,
            flexibleSpace,
            settingsButton
        ]
        
        navigationController?.isToolbarHidden = false
    }
    
    // MARK: - WebView Setup
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        // Setup message handler for future JavaScript communication
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "epubHandler")
        configuration.userContentController = userContentController
        
        // Create web view
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        view.insertSubview(webView, belowSubview: progressView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - EPUB Loading
    func loadEpub(named fileName: String = "Voy_Oborotnya") {
        guard let epubURL = Bundle.main.url(forResource: fileName, withExtension: "epub") else {
            showError(message: "EPUB файл не найден: \(fileName).epub")
            return
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let epubExtractURL = tempDirectory.appendingPathComponent("epub_\(UUID().uuidString)")
        
        // Unzip EPUB using your extension
        do {
            try FileManager.default.createDirectory(at: epubExtractURL, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: epubURL, to: epubExtractURL)
            
            // Find and load the main HTML file
            if let containerPath = findContainerFile(in: epubExtractURL),
               let contentPath = parseContainerFile(at: containerPath, baseURL: epubExtractURL),
               let htmlURL = findFirstHtmlFile(in: contentPath) {
                
                // Load the HTML file
                let request = URLRequest(url: htmlURL)
                webView.load(request)
                
                // Save path for later use
                self.epubPath = epubExtractURL.path
                loadReadingProgress()
            } else {
                showError(message: "Не удалось найти содержимое EPUB")
            }
            
        } catch {
            showError(message: "Ошибка при распаковке EPUB: \(error.localizedDescription)")
        }
    }
    
    // MARK: - EPUB Parsing Helpers
    private func findContainerFile(in directory: URL) -> URL? {
        let containerPath = directory.appendingPathComponent("META-INF/container.xml")
        return FileManager.default.fileExists(atPath: containerPath.path) ? containerPath : nil
    }
    
    private func parseContainerFile(at path: URL, baseURL: URL) -> URL? {
        do {
            let containerContent = try String(contentsOf: path, encoding: .utf8)
            
            // Parse XML using simple string methods
            // Look for rootfile with full-path attribute
            let pattern = "full-path=\"([^\"]+)\""
            
            if let range = containerContent.range(of: pattern, options: .regularExpression) {
                let match = String(containerContent[range])
                
                // Extract the path between quotes
                let components = match.components(separatedBy: "\"")
                if components.count >= 2 {
                    let relativePath = components[1]
                    return baseURL.appendingPathComponent(relativePath)
                }
            }
        } catch {
            print("Error parsing container: \(error)")
        }
        return nil
    }
    
    private func findFirstHtmlFile(in contentPath: URL) -> URL? {
        let contentDirectory = contentPath.deletingLastPathComponent()
        
        // Look for HTML files in the directory
        do {
            let files = try FileManager.default.contentsOfDirectory(at: contentDirectory, includingPropertiesForKeys: nil)
            
            // First, try to find the file referenced in the content.opf
            let opfFiles = files.filter { $0.lastPathComponent == "content.opf" }
            if let opfFile = opfFiles.first {
                // Parse OPF file to find the spine item
                if let htmlFile = parseOPFFile(at: opfFile, baseDirectory: contentDirectory) {
                    return htmlFile
                }
            }
            
            // Fallback: find any HTML/XHTML file
            if let htmlFile = files.first(where: {
                let ext = $0.pathExtension.lowercased()
                return ext == "xhtml" || ext == "html"
            }) {
                return htmlFile
            }
        } catch {
            print("Error finding HTML file: \(error)")
        }
        
        return nil
    }
    
    private func parseOPFFile(at opfURL: URL, baseDirectory: URL) -> URL? {
        do {
            let opfContent = try String(contentsOf: opfURL, encoding: .utf8)
            
            // Simple parsing - look for first itemref in spine
            // This is a simplified parser - for production use a proper XML parser
            if let itemRefRange = opfContent.range(of: "<itemref[^>]*idref=\"([^\"]+)\"", options: .regularExpression) {
                let itemRef = String(opfContent[itemRefRange])
                
                // Extract the idref value
                if let idStart = itemRef.range(of: "idref=\"")?.upperBound,
                   let idEnd = itemRef.range(of: "\"", range: idStart..<itemRef.endIndex)?.lowerBound {
                    let itemId = String(itemRef[idStart..<idEnd])
                    
                    // Now find the item with this id
                    let itemPattern = "<item[^>]*id=\"\(itemId)\"[^>]*href=\"([^\"]+)\""
                    if let itemRange = opfContent.range(of: itemPattern, options: .regularExpression) {
                        let item = String(opfContent[itemRange])
                        
                        // Extract href value
                        if let hrefStart = item.range(of: "href=\"")?.upperBound,
                           let hrefEnd = item.range(of: "\"", range: hrefStart..<item.endIndex)?.lowerBound {
                            let href = String(item[hrefStart..<hrefEnd])
                            return baseDirectory.appendingPathComponent(href)
                        }
                    }
                }
            }
        } catch {
            print("Error parsing OPF file: \(error)")
        }
        return nil
    }
    
    // MARK: - Progress Management
    private func saveReadingProgress() {
        guard let currentURL = webView.url?.absoluteString else { return }
        
        UserDefaults.standard.set(currentURL, forKey: "lastReadPosition_\(bookTitle)")
        UserDefaults.standard.synchronize()
    }
    
    private func loadReadingProgress() {
        guard let lastPosition = UserDefaults.standard.string(forKey: "lastReadPosition_\(bookTitle)"),
              let url = URL(string: lastPosition) else { return }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - Toolbar Actions
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
        // Will implement later
        print("Show chapters list")
    }
    
    @objc private func showSettings() {
        let alert = UIAlertController(title: "Настройки", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Увеличить шрифт", style: .default) { _ in
            self.changeFontSize(increase: true)
        })
        
        alert.addAction(UIAlertAction(title: "Уменьшить шрифт", style: .default) { _ in
            self.changeFontSize(increase: false)
        })
        
        alert.addAction(UIAlertAction(title: "Ночной режим", style: .default) { _ in
            self.toggleNightMode()
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = toolbarItems?.last
        }
        
        present(alert, animated: true)
    }
    
    private func changeFontSize(increase: Bool) {
        let script = """
        var style = document.getElementById('epub-custom-styles');
        if (!style) {
            style = document.createElement('style');
            style.id = 'epub-custom-styles';
            document.head.appendChild(style);
        }
        
        var currentSize = 16;
        if (style.sheet && style.sheet.cssRules.length > 0) {
            var fontSizeRule = style.sheet.cssRules[0].style.fontSize;
            if (fontSizeRule) {
                currentSize = parseInt(fontSizeRule);
            }
        }
        
        var newSize = \(increase ? "currentSize + 2" : "currentSize - 2");
        if (newSize < 10) newSize = 10;
        if (newSize > 30) newSize = 30;
        
        // Clear existing rules
        while (style.sheet.cssRules.length > 0) {
            style.sheet.deleteRule(0);
        }
        
        style.sheet.insertRule('body { font-size: ' + newSize + 'px !important; }', 0);
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func toggleNightMode() {
        let script = """
        var style = document.getElementById('epub-night-mode');
        if (!style) {
            style = document.createElement('style');
            style.id = 'epub-night-mode';
            document.head.appendChild(style);
        }
        
        switch (style.sheet.cssRules.length) {
            case 0:
                style.sheet.insertRule('body { background-color: #1a1a1a !important; color: #e0e0e0 !important; }', 0);
                style.sheet.insertRule('a { color: #4da6ff !important; }', 1);
                break;
            default:
                style.sheet.deleteRule(0);
                break;
        }
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // MARK: - Error Handling
    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension EpubReaderViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
        progressView.isHidden = false
        progressView.setProgress(0.1, animated: true)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        progressView.setProgress(0.5, animated: true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        progressView.setProgress(1.0, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.progressView.isHidden = true
        }
        
        // Inject custom CSS for better reading experience
        injectCustomCSS()
        
        // Inject JavaScript bridge for future interactivity
        injectJavaScriptBridge()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        progressView.isHidden = true
        showError(message: "Ошибка загрузки: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        progressView.isHidden = true
        showError(message: "Ошибка загрузки: \(error.localizedDescription)")
    }
    
    // Enable JavaScript on a per-navigation basis (fix for deprecated property)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        preferences.allowsContentJavaScript = true
        decisionHandler(.allow, preferences)
    }
    
    private func injectCustomCSS() {
        let css = """
        body {
            font-family: -apple-system, system-ui, sans-serif;
            line-height: 1.6;
            padding: 20px;
            max-width: 800px;
            margin: 0 auto;
        }
        
        img {
            max-width: 100%;
            height: auto;
        }
        
        .interactive-button {
            background-color: #007AFF;
            color: white;
            padding: 10px 15px;
            border-radius: 8px;
            border: none;
            cursor: pointer;
            margin: 10px 0;
        }
        
        .interactive-button:hover {
            background-color: #0056CC;
        }
        """
        
        let script = """
        var style = document.createElement('style');
        style.textContent = `\(css)`;
        document.head.appendChild(style);
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func injectJavaScriptBridge() {
        let script = """
        // JavaScript bridge for EPUB
        window.EpubBridge = {
            // Method to send messages to iOS
            sendMessage: function(action, data) {
                window.webkit.messageHandlers.epubHandler.postMessage({
                    action: action,
                    data: data
                });
            },
            
            // Method to roll dice (will be called from book content)
            rollDice: function(formula) {
                this.sendMessage('rollDice', { formula: formula });
            },
            
            // Method to show character sheet
            showCharacterSheet: function() {
                this.sendMessage('showCharacterSheet', {});
            }
        };
        
        // Make it globally available
        window.interactiveBook = window.EpubBridge;
        """
        
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("Error injecting JavaScript bridge: \(error)")
            }
        }
    }
}

// MARK: - WKUIDelegate
extension EpubReaderViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle links that open in new windows
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler
extension EpubReaderViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "epubHandler",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }
        
        switch action {
        case "rollDice":
            if let data = body["data"] as? [String: Any],
               let formula = data["formula"] as? String {
                print("Бросить кубики: \(formula)")
                // Здесь будет вызов нативного экрана броска кубиков
            }
            
        case "showCharacterSheet":
            print("Показать лист персонажа")
            // Здесь будет переход к листу характеристик
            
        default:
            print("Неизвестное действие: \(action)")
        }
    }
}
