import Foundation

// Reads and parses Claude Code's local JSONL files to produce usage statistics.
//
// Claude Code writes one .jsonl file per session inside:
//   ~/.claude/projects/<project-slug>/<session-uuid>.jsonl
//
// The project-slug is the project's file path with each "/" replaced by "-".
// For example, a project at /Users/you/dev/myapp gets the slug:
//   -Users-you-dev-myapp
//
// When an account has a pathFilter set (e.g. "/Users/you/dev"), only project
// directories whose slug starts with the equivalent prefix ("-Users-you-dev")
// are included. This lets you separate personal and work usage.
struct LocalFileDataSource {

    private let claudeProjectsRoot = NSHomeDirectory() + "/.claude/projects"

    func fetch(account: Account) async throws -> LocalFileUsage {
        let records = try parseAllJSONLFiles(pathFilter: account.pathFilter)

        let now = Date()
        let cutoff5h  = TimeWindow.last5Hours(from: now)
        let cutoff24h = TimeWindow.last24Hours(from: now)
        let cutoff7d  = TimeWindow.last7Days(from: now)

        var usage5h   = TokenUsage()
        var usage24h  = TokenUsage()
        var usage7d   = TokenUsage()
        var breakdown: [String: TokenUsage] = [:]
        var lastActivity: Date? = nil

        for record in records {
            if lastActivity == nil || record.timestamp > lastActivity! {
                lastActivity = record.timestamp
            }
            if record.timestamp > cutoff5h  { usage5h  += record.usage }
            if record.timestamp > cutoff24h { usage24h += record.usage }
            if record.timestamp > cutoff7d  {
                usage7d += record.usage
                breakdown[record.model, default: TokenUsage()] += record.usage
            }
        }

        return LocalFileUsage(
            accountId: account.id,
            last5Hours: usage5h,
            last24Hours: usage24h,
            last7Days: usage7d,
            lastActivity: lastActivity,
            modelBreakdown: breakdown,
            estimatedCostUSD: TokenCostEstimator.estimateTotal(breakdown),
            refreshedAt: now
        )
    }

    // MARK: - Private parsing

    // Returns all JSONL project directories, optionally filtered to a path prefix.
    private func parseAllJSONLFiles(pathFilter: String?) throws -> [UsageRecord] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: claudeProjectsRoot) else {
            throw LocalFileError.directoryNotFound(claudeProjectsRoot)
        }

        // Convert the user-supplied path filter to the slug prefix Claude uses.
        // "/Users/you/dev" → "-Users-you-dev"
        let slugPrefix: String? = pathFilter.map { path in
            path.replacingOccurrences(of: "/", with: "-")
        }

        // List top-level project directories, applying the slug filter if set.
        let projectDirs: [URL]
        do {
            projectDirs = try fm.contentsOfDirectory(
                at: URL(filePath: claudeProjectsRoot),
                includingPropertiesForKeys: [.isDirectoryKey]
            ).filter { url in
                var isDir: ObjCBool = false
                fm.fileExists(atPath: url.path, isDirectory: &isDir)
                guard isDir.boolValue else { return false }
                // If a filter is set, only include directories whose name starts with the prefix.
                if let prefix = slugPrefix {
                    return url.lastPathComponent.hasPrefix(prefix)
                }
                return true
            }
        } catch {
            throw LocalFileError.directoryNotFound(claudeProjectsRoot)
        }

        // Scan each project directory for .jsonl files.
        var allRecords: [UsageRecord] = []
        for projectDir in projectDirs {
            guard let enumerator = fm.enumerator(at: projectDir, includingPropertiesForKeys: nil)
            else { continue }

            var jsonlFiles: [URL] = []
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "jsonl" { jsonlFiles.append(fileURL) }
            }
            for fileURL in jsonlFiles {
                allRecords.append(contentsOf: (try? parseJSONLFile(at: fileURL)) ?? [])
            }
        }

        return allRecords
    }

    private func parseJSONLFile(at url: URL) throws -> [UsageRecord] {
        guard let fileHandle = FileHandle(forReadingAtPath: url.path) else { return [] }
        defer { fileHandle.closeFile() }

        let data = fileHandle.readDataToEndOfFile()
        guard let content = String(data: data, encoding: .utf8) else { return [] }

        var records: [UsageRecord] = []
        let decoder = JSONDecoder()

        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let lineData = String(line).data(using: .utf8) else { continue }
            guard let raw = try? decoder.decode(RawJSONLLine.self, from: lineData),
                  raw.type == "assistant",
                  let usage = raw.message?.usage,
                  let timestampString = raw.timestamp,
                  let timestamp = iso8601Formatter.date(from: timestampString)
            else { continue }

            records.append(UsageRecord(
                timestamp: timestamp,
                model: raw.message?.model ?? "unknown",
                usage: TokenUsage(
                    inputTokens:         usage.input_tokens,
                    outputTokens:        usage.output_tokens,
                    cacheCreationTokens: usage.cache_creation_input_tokens ?? 0,
                    cacheReadTokens:     usage.cache_read_input_tokens ?? 0
                )
            ))
        }
        return records
    }
}

// MARK: - Internal types

private struct UsageRecord {
    let timestamp: Date
    let model: String
    let usage: TokenUsage
}

private struct RawJSONLLine: Decodable {
    let type: String
    let timestamp: String?
    let message: RawMessage?

    struct RawMessage: Decodable {
        let model: String?
        let usage: RawUsage?
    }

    struct RawUsage: Decodable {
        let input_tokens: Int
        let output_tokens: Int
        let cache_creation_input_tokens: Int?
        let cache_read_input_tokens: Int?
    }
}

enum LocalFileError: Error, LocalizedError {
    case directoryNotFound(String)

    var errorDescription: String? {
        switch self {
        case .directoryNotFound(let path):
            return "Claude projects folder not found at: \(path)"
        }
    }
}
