#!/bin/bash

# Setup and Open script for GeoLive iOS Application
# Antigravity Developer Utility

echo "=================================================="
echo "🚀 GEOLIVE - SYSTEM CONFIGURATION & SETUP"
echo "=================================================="

# 1. Check for CocoaPods installation
if ! command -v pod &> /dev/null
then
    echo "❌ Error: CocoaPods ('pod') is not installed."
    echo "Please install it using: sudo gem install cocoapods"
    exit 1
fi

# 2. Check if Podfile exists
if [ ! -f "Podfile" ]; then
    echo "❌ Error: Podfile not found in this directory."
    exit 1
fi

echo "📦 Installing CocoaPods dependencies..."
pod install

if [ $? -eq 0 ]; then
    echo "✅ CocoaPods dependencies installed successfully!"
else
    echo "❌ Error: CocoaPods installation failed."
    exit 1
fi

# 3. Double check if workspace exists
if [ -d "GeoLive.xcworkspace" ]; then
    echo "🎉 GeoLive.xcworkspace successfully configured!"
    echo "🖥️ Opening the workspace in Xcode..."
    open GeoLive.xcworkspace
else
    echo "❌ Error: GeoLive.xcworkspace was not created."
    exit 1
fi

echo "=================================================="
echo "👍 Setup Complete! You can now build and run GeoLive."
echo "=================================================="
