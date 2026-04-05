import AppKit
import SwiftUI

// Manages the lifecycle of the Settings window using AppKit directly.
class SettingsWindowManager: ObservableObject {

    private var window: NSWindow?

    // Opens the Settings window (or brings it to front if already open).
    func open(appState: AppState, accountStore: AccountStore) {
        // Delay slightly so the MenuBarExtra panel finishes any dismiss animation
        // before we try to bring a new window to front.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.showWindow(appState: appState, accountStore: accountStore)
        }
    }

    private func showWindow(appState: AppState, accountStore: AccountStore) {
        // If the window already exists and is visible, just bring it forward.
        if let existing = window, existing.isVisible {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let content = SettingsView()
            .environmentObject(appState)
            .environmentObject(accountStore)

        let controller = NSHostingController(rootView: content)

        // NSPanel behaves better than NSWindow for auxiliary windows in menu bar apps.
        let panel = NSPanel(contentViewController: controller)
        panel.title = "ClaudeBar Settings"
        panel.setContentSize(NSSize(width: 480, height: 420))
        panel.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        // Don't hide when the app loses focus (default panel behaviour would hide it)
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.center()

        self.window = panel

        // Switch to .regular so the app can become key and bring its window to front.
        // Without this, menu bar-only apps can fail silently on makeKeyAndOrderFront.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
}
