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

```bash
.build/release/STTInput
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