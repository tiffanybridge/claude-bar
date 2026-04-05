// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClaudeBar",
            path: "Sources/ClaudeBar",
            // Link the Security framework for Keychain access
            linkerSettings: [
                .linkedFramework("Security")
            ]
        )
    ]
)
