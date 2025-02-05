import Foundation
import XcodeBuildEnvironmentParametersParser
import XcodeProjectChecksumCalculator
import Checksum

public final class TargetInfoFilter {
    
    private let targetInfoProvider: TargetInfoProvider<BaseChecksum>
    
    public init(targetInfoProvider: TargetInfoProvider<BaseChecksum>) {
        self.targetInfoProvider = targetInfoProvider
    }
    
    public func obtainRequiredTargets(
        targetName: String,
        buildParametersChecksum: BaseChecksum)
        throws -> [TargetInfo<BaseChecksum>]
    {
        let targetInfos = try targetInfoProvider.dependencies(
            for: targetName,
            buildParametersChecksum: buildParametersChecksum
        )
        return targetInfos
    }
    
    public func frameworkTargetInfos(
        _ targetInfos: [TargetInfo<BaseChecksum>])
        -> [TargetInfo<BaseChecksum>]
    {
        return targetInfos.filter { targetInfo in
            if case .bundle = targetInfo.productType {
                return false
            }
            return true
        }
    }
    
}
