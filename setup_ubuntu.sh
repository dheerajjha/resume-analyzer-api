#!/bin/bash

# Exit on error
set -e

echo "Setting up Resume PDF Converter API on Ubuntu 22.04..."

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Node.js 18.x
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Verify installation
    node --version
    npm --version
fi

# Install required system dependencies for Playwright
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
    libasound2 \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxcursor1 \
    libxss1 \
    libxtst6 \
    fonts-noto-color-emoji \
    fonts-liberation \
    xdg-utils

# Install PM2 for process management
echo "Installing PM2..."
sudo npm install -g pm2

# Install project dependencies
echo "Installing project dependencies..."
npm install

# Install Playwright browsers
echo "Installing Playwright browsers..."
npx playwright install chromium --with-deps

# Create PM2 ecosystem file
echo "Creating PM2 ecosystem file..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'resume-pdf-api',
    script: 'src/index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 8000
    }
  }]
};
EOF

# Start the application with PM2
echo "Starting the application..."
pm2 start ecosystem.config.js

# Save PM2 process list and set to start on boot
echo "Configuring PM2 startup..."
pm2 save
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME

echo "Setup completed successfully!"
echo ""
echo "The API is now running at http://localhost:8000"
echo ""
echo "Useful commands:"
echo "- View logs: pm2 logs resume-pdf-api"
echo "- Monitor: pm2 monit"
echo "- Restart: pm2 restart resume-pdf-api"
echo "- Stop: pm2 stop resume-pdf-api"
echo ""
echo "Test the API with:"
echo 'curl -X POST "http://localhost:8000/convert-to-pdf" \'
echo '     -H "Content-Type: application/json" \'
echo '     -d '"'"'{"html": "<html><body><h1>Test</h1></body></html>"}'"'"' \'
echo '     --output test.pdf' 