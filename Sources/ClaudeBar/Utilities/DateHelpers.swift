import Foundation

// Rolling time window helpers used by the local file parser.
enum TimeWindow {
    static func last5Hours(from date: Date = .now) -> Date {
        date.addingTimeInterval(-5 * 3600)
    }

    static func last24Hours(from date: Date = .now) -> Date {
        date.addingTimeInterval(-24 * 3600)
    }

    static func last7Days(from date: Date = .now) -> Date {
        date.addingTimeInterval(-7 * 24 * 3600)
    }
}

// Format a TimeInterval (in seconds) into a human-readable string.
// Used to show "Reset in: 2h 14m"
func formatTimeRemaining(_ interval: TimeInterval) -> String {
    let totalMinutes = Int(interval / 60)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else if minutes > 0 {
        return "\(minutes)m"
    } else {
        return "< 1m"
    }
}

// A standard ISO 8601 date formatter that matches Claude's JSONL timestamp format.
let iso8601Formatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()
