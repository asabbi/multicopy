import Cocoa
import Carbon
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var clipboardManager: ClipboardManager?
    var historyWindow: HistoryWindow?
    var eventTap: CFMachPort?
    var optionKeyTapTimer: Timer?
    var optionKeyTapCount: Int = 0
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("MultiCopy starting up...")
        fflush(stdout) // Force print to appear immediately
        setupMenuBar()
        setupClipboardManager()
        setupGlobalHotkeys()
        
        clipboardManager?.loadHistory()
        print("MultiCopy ready!")
        fflush(stdout)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        clipboardManager?.stopMonitoring()
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        
        optionKeyTapTimer?.invalidate()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use a simple text icon if system symbol fails
            if let clipboardImage = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "MultiCopy") {
                button.image = clipboardImage
            } else {
                button.title = "📋"
            }
            button.action = #selector(statusItemClicked)
            button.target = self
        }
        
        let menu = NSMenu()
        let showHistoryItem = NSMenuItem(title: "Show History", action: #selector(showHistory), keyEquivalent: "")
        showHistoryItem.target = self
        menu.addItem(showHistoryItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let permissionsItem = NSMenuItem(title: "Check Permissions", action: #selector(checkPermissions), keyEquivalent: "")
        permissionsItem.target = self
        menu.addItem(permissionsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func setupClipboardManager() {
        clipboardManager = ClipboardManager()
        clipboardManager?.startMonitoring()
    }
    
    private func setupGlobalHotkeys() {
        // Check for accessibility permissions first
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessibilityEnabled {
            print("Accessibility permissions required for global hotkeys")
            print("Please grant accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility")
            
            // Show a dialog to the user
            DispatchQueue.main.async {
                self.showAccessibilityPermissionDialog()
            }
            
            // Try to set up hotkeys anyway - they might grant permissions later
        }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
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
            print("Global hotkeys enabled")
        } else {
            print("Failed to create event tap - accessibility permissions may be required")
        }
    }
    
    private func showAccessibilityPermissionDialog() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permissions Required"
        alert.informativeText = "MultiCopy needs accessibility permissions to capture the double-tap Option key shortcut globally.\n\nPlease:\n1. Open System Preferences > Security & Privacy > Privacy\n2. Select 'Accessibility' from the left sidebar\n3. Click the lock icon to make changes\n4. Add or enable your terminal app\n5. Restart MultiCopy\n\nOnce enabled, double-tap the Option key to show clipboard history.\n\nFor now, you can still use the menu bar icon to access clipboard history."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Preferences
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
    
    private func handleGlobalKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        
        // Handle modifier flag changes (this is how we detect Option key presses)
        if type == .flagsChanged {
            // Check if Option key was pressed (left option = 58, right option = 61)
            if keyCode == 58 || keyCode == 61 {
                // Check if Option key was pressed (not released)
                if flags.contains(.maskAlternate) {
                    handleOptionKeyDown()
                }
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func handleOptionKeyDown() {
        optionKeyTapCount += 1
        
        if optionKeyTapCount == 1 {
            // Start timer for double-tap detection
            optionKeyTapTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                // Reset count after timeout
                self?.optionKeyTapCount = 0
            }
        } else if optionKeyTapCount == 2 {
            // Double-tap detected!
            print("Double-tap Option detected - showing history")
            optionKeyTapTimer?.invalidate()
            optionKeyTapCount = 0
            
            DispatchQueue.main.async {
                self.showHistory()
            }
        }
    }
    
    private func isTextFieldFocused() -> Bool {
        // Check if any text field or text view has focus
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            return frontApp.bundleIdentifier != Bundle.main.bundleIdentifier
        }
        return false
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
    
    @objc func checkPermissions() {
        let accessibilityEnabled = AXIsProcessTrusted()
        
        if accessibilityEnabled {
            let alert = NSAlert()
            alert.messageText = "Permissions OK"
            alert.informativeText = "MultiCopy has the necessary accessibility permissions. Double-tap the Option key should work to show clipboard history."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } else {
            showAccessibilityPermissionDialog()
        }
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}