import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController()
        requestAccessibilityIfNeeded()
    }

    private func requestAccessibilityIfNeeded() {
        if AXIsProcessTrusted() {
            EventMonitorService.shared.start()
        } else {
            let promptOptions = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(promptOptions as CFDictionary)
            pollForAccessibility()
        }
    }

    private func pollForAccessibility() {
        if AXIsProcessTrusted() {
            EventMonitorService.shared.start()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.pollForAccessibility()
            }
        }
    }
}
