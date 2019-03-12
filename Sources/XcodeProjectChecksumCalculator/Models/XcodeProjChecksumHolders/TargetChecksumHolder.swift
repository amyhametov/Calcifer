import Foundation
import Checksum

struct TargetChecksumHolder<C: Checksum>: ChecksumHolder {
    let name: String
    let productName: String
    let productType: String
    let checksum: C
    let files: [FileChecksumHolder<C>]
    let dependencies: [TargetChecksumHolder<C>]
    
    init(
        name: String,
        productName: String,
        productType: String,
        checksum: C,
        files: [FileChecksumHolder<C>],
        dependencies: [TargetChecksumHolder<C>])
    {
        self.name = name
        self.productName = productName
        self.productType = productType
        self.checksum = checksum
        self.files = files
        self.dependencies = dependencies
    }
    
    var allFrameworkDependencies: [TargetChecksumHolder<C>] {
        let all = dependencies + dependencies.flatMap { $0.allFrameworkDependencies }
        var uniq = [String: TargetChecksumHolder<C>]()
        for dependency in all {
            if dependency.productType == "com.apple.product-type.framework" {
                uniq[dependency.name] = dependency
            }
        }
        
        return Array(uniq.values)
    }
    
    // MARK: - CustomStringConvertible
    var description: String {
        return name
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case name
        case productName
        case productType
        case checksum
        case files
        case dependencies
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(productName, forKey: .productName)
        try container.encode(checksum, forKey: .checksum)
        try container.encode(files, forKey: .files)
        // Performance issue
        let dependenciesNames = dependencies.map({ $0.name })
        try container.encode(dependenciesNames, forKey: .dependencies)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        productName = try container.decode(String.self, forKey: .productName)
        productType = try container.decode(String.self, forKey: .productType)
        checksum = try container.decode(C.self, forKey: .checksum)
        files = try container.decode([FileChecksumHolder<C>].self, forKey: .files)
        // Performance issue
        dependencies = [TargetChecksumHolder<C>]()
    }
}

extension TargetChecksumHolder: TreeNodeConvertable {
    
    func node() -> TreeNode<C> {
        let children = files.nodeList() + dependencies.nodeList()
        return TreeNode<C>(
            name: name,
            value: checksum,
            children: children
        )
    }
    
}
