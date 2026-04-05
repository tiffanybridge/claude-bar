import Foundation

// Reads and parses Claude Code's local JSONL files to produce usage statistics.
//
// Claude Code writes one .jsonl file per session inside:
//   ~/.claude/projects/<project-slug>/<session-uuid>.jsonl
//
// The project-slug is the project's file path with each "/" replaced by "-".
// Records are tagged with their project slug so we can break down spend by project.
struct LocalFileDataSource {

    private let claudeProjectsRoot = NSHomeDirectory() + "/.claude/projects"

    func fetch(account: Account) async throws -> LocalFileUsage {
        let records = try parseAllJSONLFiles(includedSlugs: account.includedProjectSlugs)

        let now = Date()
        let cutoff5h    = TimeWindow.last5Hours(from: now)
        let cutoff24h   = TimeWindow.last24Hours(from: now)
        let cutoff7d    = TimeWindow.last7Days(from: now)
        let cutoffMonth = startOfCurrentMonth()

        var usage5h    = TokenUsage()
        var usage24h   = TokenUsage()
        var usage7d    = TokenUsage()
        var usageMonth = TokenUsage()
        var modelBreakdown:   [String: TokenUsage] = [:]
        var projectBreakdown: [String: TokenUsage] = [:]
        var lastActivity: Date? = nil

        for record in records {
            if lastActivity == nil || record.timestamp > lastActivity! {
                lastActivity = record.timestamp
            }
            if record.timestamp > cutoff5h    { usage5h    += record.usage }
            if record.timestamp > cutoff24h   { usage24h   += record.usage }
            if record.timestamp > cutoff7d    { usage7d    += record.usage }
            if record.timestamp > cutoffMonth {
                usageMonth += record.usage
                modelBreakdown[record.model, default: TokenUsage()] += record.usage
                projectBreakdown[record.projectSlug, default: TokenUsage()] += record.usage
            }
        }

        return LocalFileUsage(
            accountId: account.id,
            last5Hours: usage5h,
            last24Hours: usage24h,
            last7Days: usage7d,
            thisMonth: usageMonth,
            lastActivity: lastActivity,
            modelBreakdown: modelBreakdown,
            projectBreakdown: projectBreakdown,
            estimatedCostUSD: TokenCostEstimator.estimateTotal(modelBreakdown),
            refreshedAt: now
        )
    }

    // MARK: - Private parsing

    private func parseAllJSONLFiles(includedSlugs: [String]?) throws -> [UsageRecord] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: claudeProjectsRoot) else {
            throw LocalFileError.directoryNotFound(claudeProjectsRoot)
        }

        let allowedSlugs = includedSlugs.map { Set($0) }

        let projectDirs: [URL]
        do {
            projectDirs = try fm.contentsOfDirectory(
                at: URL(filePath: claudeProjectsRoot),
                includingPropertiesForKeys: [.isDirectoryKey]
            ).filter { url in
                var isDir: ObjCBool = false
                fm.fileExists(atPath: url.path, isDirectory: &isDir)
                guard isDir.boolValue else { return false }
                if let allowed = allowedSlugs {
                    return allowed.contains(url.lastPathComponent)
                }
                return true
            }
        } catch {
            throw LocalFileError.directoryNotFound(claudeProjectsRoot)
        }

        var allRecords: [UsageRecord] = []
        for projectDir in projectDirs {
            let slug = projectDir.lastPathComponent
            // Only read JSONL files directly inside the project directory.
            // Subdirectories (e.g. [session-uuid]/subagents/) contain the internal
            // API calls Claude makes when running agents — counting those alongside
            // the top-level session files inflates totals significantly.
            let topLevelFiles = (try? fm.contentsOfDirectory(
                at: projectDir,
                includingPropertiesForKeys: nil
            )) ?? []

            for fileURL in topLevelFiles where fileURL.pathExtension == "jsonl" {
                let fileRecords = (try? parseJSONLFile(at: fileURL, projectSlug: slug)) ?? []
                allRecords.append(contentsOf: fileRecords)
            }
        }

        return allRecords
    }

    private func parseJSONLFile(at url: URL, projectSlug: String) throws -> [UsageRecord] {
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
                projectSlug: projectSlug,
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

    private func startOfCurrentMonth() -> Date {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        )!
    }
}

// MARK: - Internal types

private struct UsageRecord {
    let timestamp: Date
    let projectSlug: String
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
