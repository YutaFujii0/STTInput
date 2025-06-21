# STTInput - Speech to Text Input for macOS

A lightweight macOS background utility that enhances typing productivity by allowing users to dictate text input using OpenAI's Whisper API.

## Features

- Global keyboard input monitoring
- Floating microphone button appears when typing
- Speech-to-text transcription via OpenAI Whisper API
- Direct text insertion into any application
- Runs as a background agent (no dock icon)

## Setup

### Prerequisites

- macOS 13.0 or later
- Xcode 14.0 or later
- OpenAI API key

### Installation

1. Clone the repository
2. Open Terminal and navigate to the project directory
3. Build the app:
   ```bash
   swift build -c release
   ```

### Configuration

Set your OpenAI API key using one of these methods:

1. **Environment Variable**:
   ```bash
   export OPENAI_API_KEY="your-api-key-here"
   ```

2. **Dot Environment File**:
   Create `~/.sttinput.env`:
   ```
   OPENAI_API_KEY=your-api-key-here
   ```

3. **Keychain** (most secure):
   The app will prompt you to save your API key to the keychain on first run.

### Running the App

#### Manual Run
```bash
./run.sh
```

#### Automatic Startup (Recommended)
To enable the app to start automatically at login:

```bash
chmod +x install_autostart.sh
./install_autostart.sh
```

This will:
- Build the app in release mode
- Install a launch agent that starts the app automatically at login
- Start the service immediately
- Keep the app running in the background

#### Managing the Service
Once installed, you can manage the service with these commands:

```bash
# Check service status
launchctl list | grep sttinput

# Stop the service
launchctl stop net.yutafujii.sttinput

# Restart the service
launchctl stop net.yutafujii.sttinput && launchctl start net.yutafujii.sttinput

# View logs
tail -f /tmp/sttinput.log

# Uninstall automatic startup
launchctl unload ~/Library/LaunchAgents/net.yutafujii.sttinput.plist
rm ~/Library/LaunchAgents/net.yutafujii.sttinput.plist
```

### Permissions

On first run, you'll need to grant:
- **Microphone Access**: For recording audio
- **Accessibility Access**: For monitoring keyboard input and inserting text

The app will prompt for these permissions automatically.

## Usage

1. Place your cursor where you want to insert text
2. Press the **Command key three times quickly** (⌘⌘⌘) to start recording
3. Speak your text
4. Press the **Command key twice quickly** (⌘⌘) to stop recording
   - Or click the stop button in the top-right corner
   - Or wait for auto-stop (120 seconds max)
5. The transcribed text will be inserted at your cursor position

**Key Controls**:
- **⌘⌘⌘** (triple Cmd): Start recording
- **⌘⌘** (double Cmd): Stop recording

**Note**: The keyboard triggers work from anywhere in macOS, ensuring reliable text insertion at your current cursor position without losing focus.

## Building from Xcode

If you prefer using Xcode:

1. Generate the Xcode project:
   ```bash
   swift package generate-xcodeproj
   ```
2. Open `STTInput.xcodeproj` in Xcode
3. Build and run

## License

MIT