# Resume HTML to PDF Converter API

A Node.js API service that converts HTML resumes to searchable PDFs using Playwright.

## Prerequisites

- Node.js 18.x or higher
- npm or yarn

## Setup Instructions

1. Install dependencies:
```bash
npm install
# or
yarn install
```

2. Start the server:
```bash
# Development mode with auto-reload
npm run dev
# or
yarn dev

# Production mode
npm start
# or
yarn start
```

The server will start at `http://localhost:8000`

## API Endpoints

### GET /
Health check endpoint that returns API information.

### POST /api/v1/convert-to-pdf
Converts HTML content to PDF.

Request body:
```json
{
    "html": "<your html content here>"
}
```

Response: PDF file download

## Example Usage

### Using cURL
```bash
curl -X POST "http://localhost:8000/api/v1/convert-to-pdf" \
     -H "Content-Type: application/json" \
     -d '{
       "html": "<!DOCTYPE html><html><head><title>John Doe Resume</title><style>body{font-family: Arial, sans-serif;margin: 40px;}</style></head><body><h1>John Doe</h1><p>Software Engineer</p></body></html>"
     }' \
     --output resume.pdf
```

### Using JavaScript/Node.js
```javascript
const response = await fetch('http://localhost:8000/api/v1/convert-to-pdf', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    html: `
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
    `
  })
});

if (response.ok) {
  const blob = await response.blob();
  // Save or process the PDF blob
}
```

## Development

- `npm run dev`: Start development server with auto-reload
- `npm start`: Start production server
- `npm test`: Run tests

## Project Structure

```
.
├── src/
│   └── index.js     # Main application file
├── package.json     # Project configuration
└── README.md       # Documentation
```

## Features

- Converts HTML to searchable PDF
- Maintains text searchability
- Preserves CSS styling
- Automatic cleanup of temporary files
- CORS enabled
- Security headers with Helmet
- Request logging with Morgan
- Error handling middleware

## Production Considerations

1. Environment Variables:
   - `PORT`: Server port (default: 8000)
   - Add any additional configuration as needed

2. Security:
   - Configure CORS as needed
   - Add rate limiting
   - Add authentication if required
   - Use HTTPS in production

3. Monitoring:
   - Add logging service
   - Monitor memory usage
   - Track API usage

## Troubleshooting

1. If Playwright fails to install browsers:
```bash
npx playwright install chromium
```

2. If you get permission errors:
```bash
# Fix directory permissions
sudo chown -R $USER:$USER .
```

3. Memory issues:
```bash
# Increase Node.js memory limit if needed
NODE_OPTIONS="--max-old-space-size=4096" npm start
``` 