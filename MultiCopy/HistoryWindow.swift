import Cocoa

class HistoryWindow: NSWindowController {
    
    private var window: NSWindow!
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var clipboardManager: ClipboardManager?
    private var selectedIndex: Int = 0
    
    override init(window: NSWindow?) {
        super.init(window: window)
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindow()
    }
    
    convenience init() {
        self.init(window: nil)
    }
    
    private func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Clipboard History"
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        setupTableView()
        setupScrollView()
        
        window.contentView = scrollView
        self.window = window
        
        clipboardManager = (NSApplication.shared.delegate as? AppDelegate)?.clipboardManager
    }
    
    private func setupScrollView() {
        scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = tableView
        scrollView.autoresizingMask = [.width, .height]
    }
    
    private func setupTableView() {
        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClicked)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ClipboardColumn"))
        column.title = "Clipboard History"
        column.width = 380
        tableView.addTableColumn(column)
        
        tableView.headerView = nil
        tableView.focusRingType = .none
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
    }
    
    func showWindow() {
        clipboardManager?.loadHistory()
        tableView.reloadData()
        
        if let clipboardManager = clipboardManager, !clipboardManager.history.isEmpty {
            selectedIndex = 0
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
        
        centerWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func centerWindow() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    @objc private func tableViewDoubleClicked() {
        selectCurrentItem()
    }
    
    private func selectCurrentItem() {
        guard let clipboardManager = clipboardManager,
              selectedIndex >= 0 && selectedIndex < clipboardManager.history.count else {
            return
        }
        
        let selectedEntry = clipboardManager.history[selectedIndex]
        clipboardManager.copyToClipboard(selectedEntry)
        
        window.close()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateCommandV()
        }
    }
    
    private func simulateCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: // Down arrow
            moveSelection(direction: 1)
        case 126: // Up arrow
            moveSelection(direction: -1)
        case 36: // Enter key
            selectCurrentItem()
        case 53: // Escape key
            window.close()
        default:
            super.keyDown(with: event)
        }
    }
    
    private func moveSelection(direction: Int) {
        guard let clipboardManager = clipboardManager else { return }
        
        let newIndex = selectedIndex + direction
        
        if newIndex >= 0 && newIndex < clipboardManager.history.count {
            selectedIndex = newIndex
            tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
            tableView.scrollRowToVisible(selectedIndex)
        }
    }
}

extension HistoryWindow: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return clipboardManager?.history.count ?? 0
    }
}

extension HistoryWindow: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let clipboardManager = clipboardManager,
              row < clipboardManager.history.count else {
            return nil
        }
        
        let entry = clipboardManager.history[row]
        let cellView = NSTableCellView()
        
        let textField = NSTextField()
        textField.stringValue = entry.displayText
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.lineBreakMode = .byTruncatingTail
        
        let timeLabel = NSTextField()
        timeLabel.stringValue = entry.formattedTimestamp
        timeLabel.isEditable = false
        timeLabel.isBordered = false
        timeLabel.backgroundColor = .clear
        timeLabel.font = NSFont.systemFont(ofSize: 10)
        timeLabel.textColor = .secondaryLabelColor
        
        cellView.addSubview(textField)
        cellView.addSubview(timeLabel)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            textField.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: -4),
            
            timeLabel.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8),
            timeLabel.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 24
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedIndex = tableView.selectedRow
    }
}

extension HistoryWindow: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        window.close()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
}