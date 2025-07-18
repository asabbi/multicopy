import Cocoa
import Carbon

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var clipboardManager: ClipboardManager?
    var historyWindow: HistoryWindow?
    var eventTap: CFMachPort?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenuBar()
        setupClipboardManager()
        setupGlobalHotkeys()
        
        clipboardManager?.loadHistory()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        clipboardManager?.stopMonitoring()
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "MultiCopy")
            button.action = #selector(statusItemClicked)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show History", action: #selector(showHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupClipboardManager() {
        clipboardManager = ClipboardManager()
        clipboardManager?.startMonitoring()
    }
    
    private func setupGlobalHotkeys() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) in
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()
                return appDelegate.handleGlobalKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }
    
    private func handleGlobalKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            if keyCode == 9 && flags.contains(.maskCommand) {
                showHistory()
                return nil
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    @objc func statusItemClicked() {
        showHistory()
    }
    
    @objc func showHistory() {
        if historyWindow == nil {
            historyWindow = HistoryWindow()
        }
        historyWindow?.showWindow()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}