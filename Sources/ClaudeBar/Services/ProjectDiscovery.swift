import Foundation

// Discovers all Claude Code projects on this machine and converts their
// internal directory slugs to human-readable path strings for display.
struct ProjectDiscovery {

    static let claudeProjectsRoot = NSHomeDirectory() + "/.claude/projects"

    // Returns all project slugs found in ~/.claude/projects/
    static func allSlugs() -> [String] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: claudeProjectsRoot) else {
            return []
        }
        return contents.filter { slug in
            var isDir: ObjCBool = false
            let full = claudeProjectsRoot + "/" + slug
            fm.fileExists(atPath: full, isDirectory: &isDir)
            return isDir.boolValue
        }.sorted()
    }

    // Converts a Claude-internal project slug to a display-friendly path string.
    //
    // Claude names project directories by replacing each "/" in the path with "-".
    // e.g. the project at /Users/you/dev/myapp gets the slug -Users-you-dev-myapp
    //
    // We reverse this best-effort: strip the home directory prefix and show
    // the rest as a ~/... path. Note: hyphens in folder or project names will
    // be misread as path separators — this is a display approximation only.
    static func displayName(for slug: String) -> String {
        let home = NSHomeDirectory()
        // Home path with slashes replaced by dashes (matching Claude's convention)
        let homeSlug = home.replacingOccurrences(of: "/", with: "-")
        // homeSlug is like "Users-tiffanybridge"; slugs start with "-Users-tiffanybridge-..."
        if slug.hasPrefix(homeSlug) {
            let remainder = String(slug.dropFirst(homeSlug.count))
            return "~" + remainder.replacingOccurrences(of: "-", with: "/")
        }
        // Fallback: replace all dashes with slashes and prepend /
        return "/" + slug.dropFirst().replacingOccurrences(of: "-", with: "/")
    }
}
