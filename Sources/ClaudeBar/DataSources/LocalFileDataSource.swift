import Foundation

// Reads and parses Claude Code's local JSONL files to produce usage statistics.
//
// Claude Code writes one .jsonl file per session inside:
//   ~/.claude/projects/<project-slug>/<session-uuid>.jsonl
//
// Each line is a JSON object. We care about lines where:
//   type == "assistant" AND message.usage exists
//
// Those lines contain real token counts (input, output, cache) and a timestamp.
struct LocalFileDataSource {

    // Parses all JSONL files under `projectsPath` and returns aggregated usage.
    func fetch(account: Account) async throws -> LocalFileUsage {
        let projectsPath = account.claudeProjectsPath
        let records = try parseAllJSONLFiles(in: projectsPath)

        let now = Date()
        let cutoff5h  = TimeWindow.last5Hours(from: now)
        let cutoff24h = TimeWindow.last24Hours(from: now)
        let cutoff7d  = TimeWindow.last7Days(from: now)

        var usage5h   = TokenUsage()
        var usage24h  = TokenUsage()
        var usage7d   = TokenUsage()
        var breakdown: [String: TokenUsage] = [:]  // per model, all time in 7-day window
        var lastActivity: Date? = nil

        for record in records {
            // Track the most recent message
            if lastActivity == nil || record.timestamp > lastActivity! {
                lastActivity = record.timestamp
            }

            // Accumulate into whichever windows this record falls within
            if record.timestamp > cutoff5h {
                usage5h += record.usage
            }
            if record.timestamp > cutoff24h {
                usage24h += record.usage
            }
            if record.timestamp > cutoff7d {
                usage7d += record.usage
                // Also update the per-model breakdown (7-day window only)
                breakdown[record.model, default: TokenUsage()] += record.usage
            }
        }

        let estimatedCost = TokenCostEstimator.estimateTotal(breakdown)

        return LocalFileUsage(
            accountId: account.id,
            last5Hours: usage5h,
            last24Hours: usage24h,
            last7Days: usage7d,
            lastActivity: lastActivity,
            modelBreakdown: breakdown,
            estimatedCostUSD: estimatedCost,
            refreshedAt: now
        )
    }

    // MARK: - Private parsing

    // Finds all .jsonl files recursively and parses them into UsageRecord objects.
    // This is a regular (non-async) function because FileManager and file reads are synchronous.
    private func parseAllJSONLFiles(in directory: String) throws -> [UsageRecord] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directory) else {
            throw LocalFileError.directoryNotFound(directory)
        }

        // Collect all .jsonl file URLs first (synchronous enumeration)
        guard let enumerator = fm.enumerator(
            at: URL(filePath: directory),
            includingPropertiesForKeys: nil
        ) else {
            throw LocalFileError.directoryNotFound(directory)
        }

        var jsonlFiles: [URL] = []
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "jsonl" {
                jsonlFiles.append(fileURL)
            }
        }

        var allRecords: [UsageRecord] = []
        for fileURL in jsonlFiles {
            let fileRecords = try parseJSONLFile(at: fileURL)
            allRecords.append(contentsOf: fileRecords)
        }

        return allRecords
    }

    // Reads a single .jsonl file line by line and extracts assistant usage records.
    // Reads line-by-line to avoid loading large files into memory all at once.
    private func parseJSONLFile(at url: URL) throws -> [UsageRecord] {
        guard let fileHandle = FileHandle(forReadingAtPath: url.path) else {
            return []  // Skip unreadable files rather than failing
        }
        defer { fileHandle.closeFile() }

        let data = fileHandle.readDataToEndOfFile()
        guard let content = String(data: data, encoding: .utf8) else { return [] }

        var records: [UsageRecord] = []
        let decoder = JSONDecoder()

        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let lineData = String(line).data(using: .utf8) else { continue }

            // Only try to decode assistant messages; skip everything else
            guard let raw = try? decoder.decode(RawJSONLLine.self, from: lineData),
                  raw.type == "assistant",
                  let usage = raw.message?.usage,
                  let timestampString = raw.timestamp,
                  let timestamp = iso8601Formatter.date(from: timestampString)
            else { continue }

            let model = raw.message?.model ?? "unknown"
            let tokenUsage = TokenUsage(
                inputTokens:         usage.input_tokens,
                outputTokens:        usage.output_tokens,
                cacheCreationTokens: usage.cache_creation_input_tokens ?? 0,
                cacheReadTokens:     usage.cache_read_input_tokens ?? 0
            )

            records.append(UsageRecord(timestamp: timestamp, model: model, usage: tokenUsage))
        }

        return records
    }
}

// MARK: - Internal types

// One parsed assistant message from a JSONL file.
private struct UsageRecord {
    let timestamp: Date
    let model: String
    let usage: TokenUsage
}

// Mirrors the shape of a line in Claude Code's JSONL files.
// Using optional fields because not all lines have all fields.
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
