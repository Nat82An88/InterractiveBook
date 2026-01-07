import Foundation
import Zip

extension FileManager {
    func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        try Zip.unzipFile(sourceURL, destination: destinationURL, overwrite: true, password: nil)
    }
    
    func clearTemporaryEpubFiles() {
        let tempDirectory = temporaryDirectory
        do {
            let contents = try contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            let epubDirectories = contents.filter { $0.lastPathComponent.hasPrefix("epub_") }
            
            for directory in epubDirectories {
                try removeItem(at: directory)
            }
        } catch {
            print("Ошибка очистки временных файлов: \(error)")
        }
    }
}
