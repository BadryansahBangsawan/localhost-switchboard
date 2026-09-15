import AppKit
import SwiftUI

@main
struct LocalhostSwitchboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = SwitchboardStore()

    var body: some Scene {
        MenuBarExtra("Localhost Switchboard", systemImage: "network") {
            RootView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
