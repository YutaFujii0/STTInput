#!/bin/bash

set -e

echo "Installing STTInput for automatic startup..."

# Build the app first
echo "Building STTInput..."
swift build -c release

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Create LaunchAgents directory if it doesn't exist
mkdir -p ~/Library/LaunchAgents

# Copy the plist file
cp net.yutafujii.sttinput.plist ~/Library/LaunchAgents/

echo "Launch agent installed successfully!"

# Load the launch agent
echo "Loading launch agent..."
launchctl load ~/Library/LaunchAgents/net.yutafujii.sttinput.plist

# Start the service immediately
echo "Starting STTInput service..."
launchctl start net.yutafujii.sttinput

echo ""
echo "✅ STTInput is now configured to start automatically at login!"
echo ""
echo "Useful commands:"
echo "  Check status: launchctl list | grep sttinput"
echo "  Stop service: launchctl stop net.yutafujii.sttinput"
echo "  Restart service: launchctl stop net.yutafujii.sttinput && launchctl start net.yutafujii.sttinput"
echo "  View logs: tail -f /tmp/sttinput.log"
echo "  Uninstall: launchctl unload ~/Library/LaunchAgents/net.yutafujii.sttinput.plist && rm ~/Library/LaunchAgents/net.yutafujii.sttinput.plist"
echo ""

# Check if API key is configured
if [ -z "$OPENAI_API_KEY" ] && [ ! -f ~/.sttinput.env ]; then
    echo "⚠️  Warning: No OpenAI API key found!"
    echo "Please set OPENAI_API_KEY environment variable or create ~/.sttinput.env file"
    echo "Example: echo 'OPENAI_API_KEY=your-key-here' > ~/.sttinput.env"
fi 