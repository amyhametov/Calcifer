import Foundation
import Checksum

public struct BuildProductCacheKey<ChecksumType: Checksum>: CustomStringConvertible {
    let productName: String
    let productType: TargetProductType
    let checksum: ChecksumType
    
    public init(
        productName: String,
        productType: TargetProductType,
        checksum: ChecksumType)
    {
        self.productName = productName
        self.productType = productType
        self.checksum = checksum
    }
    
    public var description: String {
        return "\(productName) \(productType) \(checksum.stringValue)"
    }
}
