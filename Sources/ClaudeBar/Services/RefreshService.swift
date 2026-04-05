import Foundation

// Fires a refresh callback on a regular interval.
// Local file reads run every 5 minutes; API calls run less often to stay under rate limits.
class RefreshService {

    // How often to auto-refresh (default 5 minutes)
    var interval: TimeInterval = 5 * 60
    private var timer: Timer?

    // Called each time the timer fires (or when triggerNow() is called).
    var onRefresh: (() async -> Void)?

    func start() {
        stop()  // Cancel any existing timer before starting a new one
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.onRefresh?() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // Trigger an immediate refresh without waiting for the next tick.
    func triggerNow() {
        Task { await onRefresh?() }
    }
}
