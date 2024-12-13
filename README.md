# Resume HTML to PDF Converter API

This API service converts HTML resumes to searchable PDFs using Playwright. It maintains text searchability and preserves all HTML/CSS styling.

## Setup Instructions

### Docker Setup (Recommended for Ubuntu)

1. Run the automated setup script:
```bash
chmod +x setup.sh
./setup.sh
```

The script will:
- Install Docker if not installed
- Create a Dockerfile and docker-compose.yml
- Build and start the Docker container
- Set up automatic restart and health checks
- Configure logging

### macOS Setup

1. Run the automated setup script:
```bash
chmod +x setup_macos.sh
./setup_macos.sh
```

The script will:
- Install Homebrew (if not installed)
- Install Python 3.11
- Set up a virtual environment
- Install all dependencies
- Install Playwright browsers
- Optionally set up auto-start on login
- Start the API server

### Manual Setup (Any Platform)

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
5. Docker Specific:
   - Use Docker secrets for sensitive data
   - Configure container resource limits
   - Set up container monitoring
   - Use Docker volumes for persistent data

## Service Management

### Docker (Ubuntu)
- Start service: `docker-compose up -d`
- Stop service: `docker-compose down`
- View logs: `docker-compose logs -f`
- Rebuild: `docker-compose up --build -d`
- Container shell: `docker-compose exec resume-pdf-api bash`
- Check status: `docker-compose ps`

### macOS
- Start service: `launchctl load ~/Library/LaunchAgents/com.resume.pdf.converter.plist`
- Stop service: `launchctl unload ~/Library/LaunchAgents/com.resume.pdf.converter.plist`
- View logs: 
  - API logs: `tail -f api.log`
  - Error logs: `tail -f api.error.log`

## Troubleshooting

1. Docker Issues:
```bash
# Check container status
docker-compose ps

# View detailed logs
docker-compose logs -f

# Restart container
docker-compose restart

# Rebuild container
docker-compose up --build -d
```

2. Permission Issues:
```bash
# Fix directory permissions
sudo chown -R $USER:$USER .

# Fix Docker permissions
sudo usermod -aG docker $USER  # Requires logout/login
```

3. Network Issues:
```bash
# Check if container is exposed
docker-compose port resume-pdf-api 8000

# Check container network
docker network ls
docker network inspect resume-analyzer-api_default
``` 