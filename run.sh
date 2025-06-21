#!/bin/bash

# Build the app in release mode
echo "Building STTInput..."
swift build -c release

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Check for API key
if [ -z "$OPENAI_API_KEY" ] && [ ! -f ~/.sttinput.env ]; then
    echo "Warning: No OpenAI API key found!"
    echo "Please set OPENAI_API_KEY environment variable or create ~/.sttinput.env file"
    echo "Example: echo 'OPENAI_API_KEY=your-key-here' > ~/.sttinput.env"
fi

# Run the app
echo "Starting STTInput..."
.build/release/STTInput