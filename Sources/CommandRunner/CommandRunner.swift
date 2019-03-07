import ArgumentsParser
import FrameworkBuilder
import ProjectChecksumCalculator
import ProjectPatcher
import BuildParametersParser
import BuildRunner

public final class CommandRunner {
    
    public init() {}
    
    public func run() -> Int32 {
        
        var registry = CommandRegistry(
            usage: "<subcommand> <options>",
            overview: "Runs specific tasks related to remote cache"
        )
        
        registry.register(command: RunCommand.self)
        registry.register(command: BuildCommand.self)
        registry.register(command: ProjectChecksumCommand.self)
        registry.register(command: ProjectChecksumDiffCommand.self)
        registry.register(command: ProjectPatcherCommand.self)
        registry.register(command: ParseCommand.self)
        
        let exitCode: Int32
        do {
            try registry.run()
            exitCode = 0
        } catch {
            exitCode = 1
            print("\(error)")
        }

        return exitCode
    }
    
}
