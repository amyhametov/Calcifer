import Foundation
import XcodeProj
import Checksum
import PathKit
import Toolkit

final class TargetChecksumHolderBuilder<Builder: URLChecksumProducer> {
        
    let builder: FileChecksumHolderBuilder<Builder>
    
    init(builder: FileChecksumHolderBuilder<Builder>) {
        self.builder = builder
    }
    
    @discardableResult
    func build(
        target: PBXTarget,
        sourceRoot: Path,
        cache: ThreadSafeDictionary<PBXTarget, TargetChecksumHolder<Builder.ChecksumType>>)
        throws -> TargetChecksumHolder<Builder.ChecksumType>
    {
        if let cachedChecksum = cache.read(target) {
            return cachedChecksum
        }
        var summarizedChecksums = [Builder.ChecksumType]()
        let dependenciesTargets = target.dependencies.compactMap { $0.target }
        let dependenciesChecksums = try dependenciesTargets.map { dependency -> TargetChecksumHolder<Builder.ChecksumType> in
            try build(
                target: dependency,
                sourceRoot: sourceRoot,
                cache: cache
            )
        }
        let dependenciesChecksum = try dependenciesChecksums.checksum()
        summarizedChecksums.append(dependenciesChecksum)
        
        let filesChecksums = try target.fileElements().map { file in
            try builder.build(file: file, sourceRoot: sourceRoot)
        }
        let filesChecksum = try filesChecksums.checksum()
        summarizedChecksums.append(filesChecksum)
        
        let summarizedChecksum = try summarizedChecksums.aggregate()
        
        var productType: TargetProductType
        if let productTypeName = target.productType?.rawValue,
            let currentProductType = TargetProductType(rawValue: productTypeName) {
             productType = currentProductType
        } else {
            productType = .none
        }
        
        let productName = try obtainProductName(for: target, type: productType)
        
        let targetChecksumHolder = TargetChecksumHolder<Builder.ChecksumType>(
            targetName: target.name,
            productName: productName,
            productType: productType,
            checksum: summarizedChecksum,
            files: filesChecksums,
            dependencies: dependenciesChecksums
        )
        cache.write(targetChecksumHolder, for: target)
        return targetChecksumHolder
    }
    
    private func obtainProductName(for target: PBXTarget, type: TargetProductType) throws -> String {
        // target.productName is not correct. Mb should use buildSettings
        if let productName = target.product?.name,
            isValidProductName(productName, type: type) {
            return productName
        }
        if let productName = target.product?.path,
            isValidProductName(productName, type: type) {
            return productName
        }
        if let productName = target.productNameWithExtension(),
            isValidProductName(productName, type: type) {
            return productName
        }
        throw XcodeProjectChecksumCalculatorError.emptyProductName(
            target: target.name
        )
    }
    
    private func isValidProductName(_ productName: String, type: TargetProductType) -> Bool {
        switch type {
        case .framework:
            return productName.contains("-") == false
        default:
            return true
        }
    }
}

extension PBXTarget {
    func fileElements() -> [PBXFileElement] {
        var files = [PBXFileElement]()
        if let sourcesBuildPhase = try? sourcesBuildPhase() {
            let sourcesFileElement = sourcesBuildPhase.fileElements()
            files.append(contentsOf: sourcesFileElement)
        }
        
        if let productType = productType, case .bundle = productType {
            if let resourcesBuildPhase = try? resourcesBuildPhase() {
                let resourcesFileElement = resourcesBuildPhase.fileElements()
                files.append(contentsOf: resourcesFileElement)
            }
        }
        return files
    }
}

extension PBXBuildPhase {
    func fileElements() -> [PBXFileElement] {
        guard let files = files else { return [PBXFileElement]() }
        return files.compactMap { $0.file }
    }
}
