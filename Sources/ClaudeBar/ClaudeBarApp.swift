import SwiftUI
import AppKit

@main
struct ClaudeBarApp: App {

    @StateObject private var accountStore: AccountStore
    @StateObject private var appState: AppState
    @StateObject private var settingsManager = SettingsWindowManager()

    init() {
        let store = AccountStore()
        _accountStore = StateObject(wrappedValue: store)
        _appState = StateObject(wrappedValue: AppState(accountStore: store))
    }

    var body: some Scene {
        MenuBarExtra(appState.statusBarText, systemImage: "brain.head.profile") {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(accountStore)
                .environmentObject(settingsManager)
                .frame(width: 320)
        }
        .menuBarExtraStyle(.window)
    }
}
