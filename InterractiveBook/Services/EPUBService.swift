import Foundation
import Zip

protocol EPUBServiceProtocol {
    func loadBook(named fileName: String) throws -> URL
    func extractEPUB(at url: URL) throws -> URL
    func parseContainerFile(at url: URL) throws -> URL
    func findFirstHTML(in directory: URL) throws -> URL
    func getTableOfContents(from directory: URL) throws -> [Chapter]
}

struct Chapter {
    let title: String
    let url: URL
}

class EPUBService: EPUBServiceProtocol {
    enum EPubError: Error {
        case fileNotFound
        case extractionFailed
        case containerNotFound
        case contentNotFound
        case invalidXML
    }
    
    private let fileManager = FileManager.default
    
    func loadBook(named fileName: String) throws -> URL {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "epub") else {
            throw EPubError.fileNotFound
        }
        return url
    }
    
    func extractEPUB(at url: URL) throws -> URL {
        let tempDirectory = fileManager.temporaryDirectory
        let extractURL = tempDirectory.appendingPathComponent("epub_\(UUID().uuidString)")
        
        do {
            try fileManager.createDirectory(at: extractURL, withIntermediateDirectories: true)
            try Zip.unzipFile(url, destination: extractURL, overwrite: true, password: nil)
            return extractURL
        } catch {
            throw EPubError.extractionFailed
        }
    }
    
    func parseContainerFile(at url: URL) throws -> URL {
        let containerPath = url.appendingPathComponent("META-INF/container.xml")
        
        guard fileManager.fileExists(atPath: containerPath.path) else {
            throw EPubError.containerNotFound
        }
        
        do {
            let containerContent = try String(contentsOf: containerPath, encoding: .utf8)
            
            // Парсим XML для нахождения content.opf
            guard let rootfileRange = containerContent.range(of: "full-path=\"([^\"]+)\"", options: .regularExpression) else {
                throw EPubError.invalidXML
            }
            
            let match = String(containerContent[rootfileRange])
            let components = match.components(separatedBy: "\"")
            
            guard components.count >= 2 else {
                throw EPubError.invalidXML
            }
            
            let relativePath = components[1]
            return url.appendingPathComponent(relativePath)
            
        } catch {
            throw EPubError.contentNotFound
        }
    }
    
    func findFirstHTML(in directory: URL) throws -> URL {
        let contentDirectory = directory.deletingLastPathComponent()
        
        // Сначала пытаемся найти и распарсить content.opf
        let opfFiles = try fileManager.contentsOfDirectory(at: contentDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent == "content.opf" }
        
        if let opfFile = opfFiles.first,
           let htmlFile = try? parseOPFFile(at: opfFile, baseDirectory: contentDirectory) {
            return htmlFile
        }
        
        // Fallback: ищем любой HTML файл
        let htmlFiles = try fileManager.contentsOfDirectory(at: contentDirectory, includingPropertiesForKeys: nil)
            .filter { ["xhtml", "html", "htm"].contains($0.pathExtension.lowercased()) }
        
        guard let firstHTML = htmlFiles.first else {
            throw EPubError.contentNotFound
        }
        
        return firstHTML
    }
    
    func getTableOfContents(from directory: URL) throws -> [Chapter] {
        let contentDirectory = directory.deletingLastPathComponent()
        var chapters: [Chapter] = []
        
        // Поиск файла toc.ncx или аналогичного
        let ncxFiles = try fileManager.contentsOfDirectory(at: contentDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.lowercased().contains("toc") }
        
        // Упрощенная реализация - для полной нужно парсить toc.ncx
        if let ncxFile = ncxFiles.first {
            chapters = try parseNCXFile(at: ncxFile, baseDirectory: contentDirectory)
        }
        
        return chapters
    }
    
    // MARK: - Private Methods
    
    private func parseOPFFile(at opfURL: URL, baseDirectory: URL) throws -> URL? {
        let opfContent = try String(contentsOf: opfURL, encoding: .utf8)
        
        // Ищем первый itemref в spine
        let itemRefPattern = "<itemref[^>]*idref=\"([^\"]+)\""
        guard let itemRefRange = opfContent.range(of: itemRefPattern, options: .regularExpression) else {
            return nil
        }
        
        let itemRef = String(opfContent[itemRefRange])
        
        // Извлекаем idref
        guard let idStart = itemRef.range(of: "idref=\"")?.upperBound,
              let idEnd = itemRef.range(of: "\"", range: idStart..<itemRef.endIndex)?.lowerBound else {
            return nil
        }
        
        let itemId = String(itemRef[idStart..<idEnd])
        
        // Ищем item с этим id
        let itemPattern = "<item[^>]*id=\"\(itemId)\"[^>]*href=\"([^\"]+)\""
        guard let itemRange = opfContent.range(of: itemPattern, options: .regularExpression) else {
            return nil
        }
        
        let item = String(opfContent[itemRange])
        
        // Извлекаем href
        guard let hrefStart = item.range(of: "href=\"")?.upperBound,
              let hrefEnd = item.range(of: "\"", range: hrefStart..<item.endIndex)?.lowerBound else {
            return nil
        }
        
        let href = String(item[hrefStart..<hrefEnd])
        return baseDirectory.appendingPathComponent(href)
    }
    
    private func parseNCXFile(at ncxURL: URL, baseDirectory: URL) throws -> [Chapter] {
        // Упрощенная реализация парсинга NCX
        let content = try String(contentsOf: ncxURL, encoding: .utf8)
        var chapters: [Chapter] = []
        
        // Регулярное выражение для поиска navPoints
        let pattern = "<navPoint[^>]*>.*?<text>([^<]+)</text>.*?<content[^>]*src=\"([^\"]+)\""
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        
        for match in matches {
            if let titleRange = Range(match.range(at: 1), in: content),
               let srcRange = Range(match.range(at: 2), in: content) {
                
                let title = String(content[titleRange])
                let src = String(content[srcRange])
                let url = baseDirectory.appendingPathComponent(src)
                
                chapters.append(Chapter(title: title, url: url))
            }
        }
        
        return chapters
    }
}
