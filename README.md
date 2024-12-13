# Resume HTML to PDF Converter API

This API service converts HTML resumes to searchable PDFs using Playwright. It maintains text searchability and preserves all HTML/CSS styling.

## Local Setup

### Prerequisites
- Python 3.11 or higher
- pip (Python package manager)
- virtualenv

### Local Installation Steps

1. Create a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Install Playwright browsers:
```bash
playwright install
```

4. Run the API server:
```bash
python main.py
```

The server will start at `http://localhost:8000`

## Ubuntu Server Deployment

### One-Click Setup Script
Save this as `setup.sh` in your server:

```bash
#!/bin/bash

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Python and required system dependencies
sudo apt-get install -y python3.11 python3.11-venv python3-pip

# Install additional dependencies for Playwright
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
python3.11 -m venv venv
source venv/bin/activate

# Upgrade pip and install requirements
pip install --upgrade pip
pip install -r requirements.txt

# Install Playwright browsers
playwright install

# Create systemd service file
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
sudo systemctl daemon-reload
sudo systemctl start resume-pdf-api
sudo systemctl enable resume-pdf-api

echo "Setup completed! The API service is now running."
```

Make the script executable and run it:
```bash
chmod +x setup.sh
./setup.sh
```

## API Endpoints

### POST /convert-to-pdf
Converts HTML content to PDF.

Request body:
```json
{
    "html": "<your html content here>"
}
```

Response: PDF file download

### GET /
Health check endpoint that returns API information.

## Example Usage

### Using cURL
```bash
curl -X POST "http://localhost:8000/convert-to-pdf" \
     -H "Content-Type: application/json" \
     -d '{
       "html": "<!DOCTYPE html><html><head><title>John Doe Resume</title><style>body{font-family: Arial, sans-serif;margin: 40px;}</style></head><body><h1>John Doe</h1><p>Software Engineer</p></body></html>"
     }' \
     --output resume.pdf
```

### Using Python Requests
```python
import requests

url = "http://localhost:8000/convert-to-pdf"
html_content = """
<!DOCTYPE html>
<html>
<head>
    <title>John Doe Resume</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
    </style>
</head>
<body>
    <h1>John Doe</h1>
    <p>Software Engineer</p>
</body>
</html>
"""

response = requests.post(
    url,
    json={"html": html_content},
    stream=True
)

if response.status_code == 200:
    with open("resume.pdf", "wb") as f:
        f.write(response.content)
```

## Production Considerations

1. SSL/TLS: For production, configure SSL certificates using Nginx or similar.
2. Rate Limiting: Implement rate limiting for the API endpoints.
3. Authentication: Add API key authentication for production use.
4. Monitoring: Set up monitoring and logging.

## Troubleshooting

1. If Playwright fails to install browsers:
```bash
# Try installing with sudo
sudo playwright install
```

2. If you get permission errors:
```bash
# Fix directory permissions
sudo chown -R $USER:$USER .
```

3. If the service fails to start:
```bash
# Check service status
sudo systemctl status resume-pdf-api
# Check logs
sudo journalctl -u resume-pdf-api
``` 