import Foundation
import PathKit
import xcodeproj

public final class ProjectPatcher {
    
    public init() {}
    
    public func patch(projectPath: String, outputPath: String, targets: [String]) throws {
        let path = Path(projectPath)
        let xcodeproject = try XcodeProj(path: path)
        let pbxproj = xcodeproject.pbxproj
        guard let project = try pbxproj.rootProject() else { return }
        let agregateTarget = PBXAggregateTarget(name: "Aggregate")
        var targetsForRemoving = [String]()

        project.targets.enumerated().forEach({ index, target in
            if targets.contains(target.name) {
                let dependency = PBXTargetDependency(
                    name: target.name,
                    target: target,
                    targetProxy: nil
                )
                pbxproj.add(object: dependency)
                agregateTarget.dependencies.append(dependency)
            } else {
                targetsForRemoving.append(target.name)
            }
        })
        targetsForRemoving.forEach { targetName in
            if let index = project.targets.firstIndex(where: { $0.name == targetName }) {
                // This is necessary because of an error about duplication of heders
                // (One inside the framework, the other in the source).
                // Perhaps this can be corrected in another way.
                let target = project.targets[index]
                removeGroup(for: target, pbxproj: pbxproj, project: project)

                project.targets.remove(at: index)
            }
        }
        pbxproj.add(object: agregateTarget)
        project.targets.append(agregateTarget)
        try xcodeproject.write(path: Path(outputPath))
    }
    
    private func removeGroup(for target: PBXTarget, pbxproj: PBXProj, project: PBXProject) {
        let podsGroup = project.mainGroup.group(named: "Pods")
        let developmentPodsGroup = project.mainGroup.group(named: "Development Pods")
        if let targetGroup = podsGroup?.group(named: target.name) {
            pbxproj.delete(object: targetGroup)
        }
        if let targetGroup = developmentPodsGroup?.group(named: target.name) {
            pbxproj.delete(object: targetGroup)
        }
        if let productName = target.productName {
            if let targetGroup = podsGroup?.group(named: productName) {
                pbxproj.delete(object: targetGroup)
            }
            if let targetGroup = developmentPodsGroup?.group(named: productName) {
                pbxproj.delete(object: targetGroup)
            }
        }
    }
    
}
