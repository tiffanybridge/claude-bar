import AppKit
import SwiftUI

// Manages the lifecycle of the Settings window using AppKit directly.
//
// SwiftUI's openWindow(id:) doesn't work from inside a MenuBarExtra panel —
// the panel runs in an isolated window context that doesn't receive the
// standard SwiftUI window environment. This class works around that by
// creating and showing the window via AppKit, which always works.
class SettingsWindowManager: ObservableObject {

    private var window: NSWindow?

    // Opens the Settings window (or brings it to front if already open).
    func open(appState: AppState, accountStore: AccountStore) {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Wrap the SwiftUI SettingsView in an NSHostingController so AppKit can display it.
        let content = SettingsView()
            .environmentObject(appState)
            .environmentObject(accountStore)

        let controller = NSHostingController(rootView: content)
        let win = NSWindow(contentViewController: controller)
        win.title = "ClaudeBar Settings"
        win.setContentSize(NSSize(width: 480, height: 400))
        win.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        win.center()
        // Release the window reference when it closes, so re-opening creates a fresh one.
        win.isReleasedWhenClosed = false

        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
