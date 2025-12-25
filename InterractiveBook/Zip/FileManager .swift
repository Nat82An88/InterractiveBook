import Foundation
import Zip

extension FileManager {
    func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        try Zip.unzipFile(sourceURL, destination: destinationURL, overwrite: true, password: nil)
    }
}
