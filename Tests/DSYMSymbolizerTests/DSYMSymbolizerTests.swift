import Foundation
import XCTest
import ShellCommand
import Toolkit
import Mock
@testable import DSYMSymbolizer

public final class DSYMSymbolizerTests: XCTestCase {
    
    let fileManager = FileManager.default
    
    func test_symbolizer() {
        XCTAssertNoThrow(try {
            // Given
            let uuid = UUID().uuidString
            let expectedArchitecture = "x86_64"
            let sourcePath = "source_path"
            let buildSourcePath = "build_source_path"
            let binaryPath = "binary_path"
            let binaryPathInApp = "binary_path_in_app"
            
            let dSYMPath = createDSYM()
            
            let plistPath = dSYMPath
                .appendingPathComponent("Contents")
                .appendingPathComponent("Resources")
                .appendingPathComponent("\(uuid).plist")
            
            let symbolizer = createSymbolizer(
                binaryPath: binaryPath,
                dsymBundlePath: dSYMPath,
                uuid: uuid,
                architecture: expectedArchitecture
            )
            
            // When
            try symbolizer.symbolize(
                dsymBundlePath: dSYMPath,
                sourcePath: sourcePath,
                buildSourcePath: buildSourcePath,
                binaryPath: binaryPath,
                binaryPathInApp: binaryPathInApp
            )
            
            // Then
            guard let plistContent = NSDictionary(contentsOfFile: plistPath)
                as? [String: String]
                else {
                    XCTFail("Empty plist content")
                    return
                }
            let architecture: String? = plistContent["DBGArchitecture"]
            XCTAssertEqual(architecture, expectedArchitecture)
            XCTAssertEqual(plistContent["DBGBuildSourcePath"], buildSourcePath)
            XCTAssertEqual(plistContent["DBGSourcePath"], sourcePath)
            XCTAssertEqual(plistContent["DBGSymbolRichExecutable"], binaryPathInApp)
        }(), "Caught exception")
    }
    
    private func createSymbolizer(
        binaryPath: String,
        dsymBundlePath: String,
        uuid: String,
        architecture: String)
        -> DSYMSymbolizer
    {
        let shellCommandExecutor = ShellCommandExecutorStub { command in
            XCTFail(
                "Incorrect command launchPath \(command.launchPath) or arguments \(command.arguments)"
            )
        }
        let output = [
            "UUID: \(uuid) (\(architecture))",
            "/Users/a/.calcifer/localCache/Unbox/9d4f...10f1/Unbox.framework/Unbox"
        ].joined(separator: " ")
        let stubs = [binaryPath, dsymBundlePath].map {
            ShellCommandStub(
                launchPath: "/usr/bin/dwarfdump",
                arguments: [
                    "--uuid",
                    $0
                ],
                output: output
            )
        }
        shellCommandExecutor.stubCommand(stubs)
        let uuidProvider = DWARFUUIDProviderImpl(
            shellCommandExecutor: shellCommandExecutor
        )
        return DSYMSymbolizer(
            dwarfUUIDProvider: uuidProvider,
            fileManager: fileManager
        )
    }
    
    private func createDSYM() -> String {
        let name = UUID().uuidString
        let dsymPath = URL(
            fileURLWithPath: NSTemporaryDirectory()
        ).appendingPathComponent("\(name).framework.dSYM")
        let dwarfDirecotry = dsymPath
            .appendingPathComponent("Contents")
            .appendingPathComponent("Resources")
            .appendingPathComponent("DWARF")
        return catchError { () -> String in
            try fileManager.createDirectory(
                atPath: dwarfDirecotry.path,
                withIntermediateDirectories: true
            )
            let dwarfPath = dwarfDirecotry.appendingPathComponent(name)
            fileManager.createFile(atPath: dwarfPath.path, contents: nil)
            return dsymPath.path
        }
    }
    
}
