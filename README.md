# MultiCopy - Mac Clipboard History Manager

A simple Mac desktop application that keeps track of your clipboard history and provides quick access to previously copied text.

## Features

- **Automatic Clipboard Monitoring**: Detects when you copy text with Cmd+C and stores it in history
- **Double-Tap Option Key**: Press Option key twice quickly to show clipboard history
- **Smart Pasting**: Automatically returns focus to the originating application and pastes selected text
- **Keyboard Navigation**: Use arrow keys to navigate through history entries
- **Quick Selection**: Press Enter to select and paste an entry
- **Persistent Storage**: History is saved and restored between app sessions
- **Menu Bar Integration**: Lives in your menu bar for easy access

## Usage

1. **Copy Text**: Use Cmd+C to copy text as usual - it will be automatically added to history
2. **Access History**: Double-tap the Option key to open the clipboard history window
3. **Navigate**: Use Up/Down arrow keys to browse through entries
4. **Select**: Press Enter to select an entry - it will automatically paste to the originating text field
5. **Cancel**: Press Escape to close the history window

### Alternative Access
- Click the clipboard icon in your menu bar to access history
- Use "Show History" from the menu bar dropdown

## Building and Running

### Prerequisites
- macOS 12.0 or later
- Swift 5.7 or later

### Build Instructions

1. Clone or download the project
2. Open Terminal and navigate to the project directory
3. Run: `swift build`
4. Run: `swift run MultiCopy`

### Xcode Project (Alternative)
The project also includes Xcode project files if you prefer to build with Xcode.

## Permissions

The app requires **Accessibility permissions** to:
- Monitor global keyboard shortcuts
- Simulate keystrokes for pasting

You'll be prompted to grant these permissions when you first run the app.

## Architecture

- **AppDelegate**: Main application controller with menu bar setup
- **ClipboardManager**: Handles clipboard monitoring and history storage
- **HistoryWindow**: UI for displaying and navigating clipboard history
- **ClipboardEntry**: Data model for individual clipboard entries

## Limitations

- Text-only clipboard support (no images, files, etc.)
- History limited to 100 entries
- Requires accessibility permissions for global hotkeys

## License

This project is provided as-is for educational and personal use.