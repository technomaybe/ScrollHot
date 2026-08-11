import AppKit
import CoreGraphics
import Foundation

// Singleton accessed on the main thread only.
final class EventMonitorService {
    static let shared = EventMonitorService()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Scroll-wheel click is delivered as otherMouseDown with buttonNumber == 2.
    private let scrollWheelButtonNumber: Int64 = 2

    private init() {}

    func start() {
        guard eventTap == nil else { return }

        let mask: CGEventMask = 1 << CGEventType.otherMouseDown.rawValue
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: middleButtonCallback,
            userInfo: refcon
        ) else {
            NSLog("ScrollHot: failed to create CGEventTap — check Accessibility permission")
            return
        }

        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = src
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    // The system disables a tap (without telling the owning process) if its callback
    // ever blocks past its watchdog timeout, or if the user disables it via
    // Accessibility settings. Left alone, the app would silently stop remapping until
    // relaunched, so re-enable it the moment we're notified.
    fileprivate func handleTapDisabled() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    // Called from the C callback — runs on the main run loop.
    func handleMiddleButton(event: CGEvent) -> Unmanaged<CGEvent>? {
        let store = SettingsStore.shared
        guard store.isEnabled, let hotKey = store.hotKey else {
            return Unmanaged.passRetained(event)
        }
        guard event.getIntegerValueField(.mouseEventButtonNumber) == scrollWheelButtonNumber else {
            return Unmanaged.passRetained(event)
        }

        HotKeyEmitter.emit(hotKey)
        store.lastFired = Date()
        return nil  // consume the event so the default middle-click action doesn't also fire
    }
}

// MARK: - C callback (must be a free function)

private func middleButtonCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passRetained(event) }
    let service = Unmanaged<EventMonitorService>.fromOpaque(refcon).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        service.handleTapDisabled()
        return Unmanaged.passRetained(event)
    }

    return service.handleMiddleButton(event: event)
}
