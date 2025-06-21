#!/bin/bash

echo "Building STTInput..."
swift build

echo "Running STTInput with console output..."
echo "Press Cmd three times to start recording"
echo "Press Ctrl+C to quit"
echo "---"

.build/debug/STTInput