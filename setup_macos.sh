#!/bin/bash

# Exit on error
set -e

echo "Starting Resume PDF Converter API setup for macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed. Updating..."
    brew update
fi

# Install Python 3.11 if not installed
if ! command -v python3.11 &> /dev/null; then
    echo "Installing Python 3.11..."
    brew install python@3.11
else
    echo "Python 3.11 is already installed"
fi

# Ensure pip is up to date
echo "Upgrading pip..."
python3.11 -m pip install --upgrade pip

# Create and activate virtual environment
echo "Setting up Python virtual environment..."
python3.11 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Install Playwright browsers
echo "Installing Playwright browsers..."
playwright install chromium

# Create launch agent for auto-start (optional)
read -p "Would you like to set up the API to start automatically on login? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create launch agent directory if it doesn't exist
    mkdir -p ~/Library/LaunchAgents

    # Create launch agent plist file
    cat > ~/Library/LaunchAgents/com.resume.pdf.converter.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.resume.pdf.converter</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(pwd)/venv/bin/python</string>
        <string>$(pwd)/main.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>$(pwd)</string>
    <key>StandardOutPath</key>
    <string>$(pwd)/api.log</string>
    <key>StandardErrorPath</key>
    <string>$(pwd)/api.error.log</string>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

    # Load the launch agent
    launchctl load ~/Library/LaunchAgents/com.resume.pdf.converter.plist
    echo "Launch agent installed. The API will start automatically on login."
fi

# Start the API server
echo "Starting the API server..."
python main.py &

echo "Setup completed successfully!"
echo "The API is now running at http://localhost:8000"
echo ""
echo "Additional Information:"
echo "- Virtual environment location: $(pwd)/venv"
echo "- To activate the virtual environment: source venv/bin/activate"
echo "- To deactivate: deactivate"
echo "- To start the server manually: python main.py"
echo "- API Documentation: http://localhost:8000/docs"
echo ""
echo "If you set up auto-start:"
echo "- To stop the service: launchctl unload ~/Library/LaunchAgents/com.resume.pdf.converter.plist"
echo "- To start the service: launchctl load ~/Library/LaunchAgents/com.resume.pdf.converter.plist"
echo "- Logs are available at: $(pwd)/api.log and $(pwd)/api.error.log" 