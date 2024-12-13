#!/bin/bash

# Exit on error
set -e

echo "Starting Resume PDF Converter API setup..."

# Update system packages
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Python and required system dependencies
echo "Installing Python and system dependencies..."
sudo apt-get install -y python3.11 python3.11-venv python3-pip

# Install additional dependencies for Playwright
echo "Installing Playwright dependencies..."
sudo apt-get install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2

# Create and activate virtual environment
echo "Setting up Python virtual environment..."
python3.11 -m venv venv
source venv/bin/activate

# Upgrade pip and install requirements
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Install Playwright browsers
echo "Installing Playwright browsers..."
playwright install chromium

# Create systemd service file
echo "Creating systemd service..."
sudo tee /etc/systemd/system/resume-pdf-api.service << EOF
[Unit]
Description=Resume PDF Converter API
After=network.target

[Service]
User=$USER
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin"
ExecStart=$(pwd)/venv/bin/python main.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
echo "Starting the service..."
sudo systemctl daemon-reload
sudo systemctl start resume-pdf-api
sudo systemctl enable resume-pdf-api

echo "Setup completed successfully!"
echo "The API service is now running at http://localhost:8000"
echo "To check the service status: sudo systemctl status resume-pdf-api"
echo "To view logs: sudo journalctl -u resume-pdf-api" 