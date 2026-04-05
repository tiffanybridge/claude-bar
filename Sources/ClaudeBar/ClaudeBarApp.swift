import SwiftUI
import AppKit

@main
struct ClaudeBarApp: App {

    @StateObject private var accountStore = AccountStore()
    @StateObject private var appState: AppState

    // We need a custom init to pass accountStore into AppState before @StateObject initializes it.
    // This is a standard pattern for injecting dependencies between ObservableObjects.
    init() {
        let store = AccountStore()
        _accountStore = StateObject(wrappedValue: store)
        _appState = StateObject(wrappedValue: AppState(accountStore: store))
    }

    var body: some Scene {
        // MenuBarExtra creates the menu bar icon and its dropdown panel.
        // .window style lets us put arbitrary SwiftUI views inside the panel.
        MenuBarExtra(appState.statusBarText, systemImage: "brain.head.profile") {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(accountStore)
                .frame(width: 320)
        }
        .menuBarExtraStyle(.window)

        // A separate Settings window, opened from the gear button in the panel.
        // It won't appear in the Dock; only via the gear button.
        WindowGroup("Settings", id: "settings") {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(accountStore)
                .frame(minWidth: 420, minHeight: 300)
        }
        .windowResizability(.contentSize)
    }
}
