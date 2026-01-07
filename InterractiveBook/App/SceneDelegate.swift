import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Создаем тестовую книгу
        let testBook = Book(title: "Вой оборотня", fileName: "Voy_Oborotnya")
        
        // Создаем ViewModel для читалки
        let readerVM = ReaderViewModel(book: testBook)
        let readerVC = EpubReaderViewController(viewModel: readerVM)
        
        // Пока используем навигационный контроллер
        // Позже заменим на TabBarController
        let navController = UINavigationController(rootViewController: readerVC)
        navController.navigationBar.prefersLargeTitles = true
        
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Очищаем временные файлы EPUB
        FileManager.default.clearTemporaryEpubFiles()
    }
}
