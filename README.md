# Clippo

Clippo is a modern, lightweight, and secure clipboard manager for macOS. It helps you keep track of your clipboard history, organize copied items, and access them instantly with a customizable global shortcut.

## Features

- **Clipboard History**: Automatically saves text, links, and other content you copy.
- **Global Hotkey**: Access your clipboard history from anywhere using `Cmd + Shift + V` (customizable).
- **Privacy Focused**:
    - **Password Detection**: Automatically detects potential passwords and sensitive information to prevent them from being stored in clear text or persistent history.
    - **Local Storage**: All your data stays on your device.
- **Smart Management**:
    - **Ignored Items**: Ability to ignore specific items or apps.
- **Modern UI**: Clean and native macOS interface with support for dark mode.
- **Onboarding Flow**: Guided setup to ensure necessary permissions (Accessibility) are granted.

## Requirements

- macOS 12.0 or later

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/shreeyashsalunke/Clippo.git
   ```
2. Open the project in Xcode:
   ```bash
   cd Clippo
   open Clippo.xcodeproj
   ```
3. Build and Run the `Clippo` target.

## Usage

1. Launch Clippo.
2. Grant the necessary Accessibility permissions when prompted (required for clipboard monitoring).
3. Copy text or content from any application using `Cmd + C`.
4. Press `Cmd + Shift + V` to open the Clippo overlay.
5. Select an item to paste it into the active application.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Privacy Policy

For detailed information on how Clippo handles your data, please verify the [Privacy Policy](PRIVACY_POLICY.md).