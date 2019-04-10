import Foundation
import Checksum

public final class LocalBuildProductCacheStorage<ChecksumType: Checksum>: BuildProductCacheStorage {
    
    private let fileManager: FileManager
    private let cacheDirectoryPath: String
    
    public init(fileManager: FileManager, cacheDirectoryPath: String) {
        self.fileManager = fileManager
        self.cacheDirectoryPath = cacheDirectoryPath
    }
    
    // MARK: - FrameworkCacheStorage
    public func cached(for cacheKey: BuildProductCacheKey<ChecksumType>) throws -> BuildProductCacheValue<ChecksumType>? {
        let entryURL = url(to: cacheKey)
        if fileManager.directoryExist(at: entryURL) {
            return BuildProductCacheValue(key: cacheKey, path: entryURL.path)
        }
        return nil
    }
    
    public func add(cacheKey: BuildProductCacheKey<ChecksumType>, at artifactPath: String) throws {
        let artifactURL = URL(fileURLWithPath: artifactPath)
        let entryURL = url(to: cacheKey)
        
        let entryFolderURL = entryURL.deletingLastPathComponent()
        if fileManager.directoryExist(at: entryFolderURL) {
            try fileManager.removeItem(at: entryFolderURL)
        }
        try fileManager.createDirectory(
            at: entryFolderURL,
            withIntermediateDirectories: true
        )
        
        try fileManager.copyItem(at: artifactURL, to: entryURL)
    }
    
    @inline(__always) private func url(
        to cacheKey: BuildProductCacheKey<ChecksumType>)
        -> URL
    {
        return URL(fileURLWithPath: path(to: cacheKey))
    }
    
    private func path(to cacheKey: BuildProductCacheKey<ChecksumType>) -> String {
        var path = cacheDirectoryPath
            .appendingPathComponent(cacheKey.productType.rawValue)
            .appendingPathComponent(cacheKey.productName)
            .appendingPathComponent(cacheKey.checksum.stringValue)
            .appendingPathComponent(cacheKey.productName)
        path.append(cacheKey.productType.fileExtension)
        return path
    }
    
}
