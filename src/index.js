const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs').promises;
const os = require('os');
const https = require('https');
const http = require('http');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 4000;
const httpsPort = process.env.HTTPS_PORT || 3443;
const domain = process.env.DOMAIN || 'localhost';
const isProduction = process.env.NODE_ENV === 'production';

// Default PDF configuration
const DEFAULT_CONFIG = {
  format: 'A4',
  printBackground: true,
  margin: {
    top: '20px',
    right: '20px',
    bottom: '20px',
    left: '20px'
  },
  scale: 1.0,
  landscape: false,
  preferCSSPageSize: false,
  displayHeaderFooter: false,
  headerTemplate: '',
  footerTemplate: '',
  pageRanges: ''
};

// Middleware
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json({ limit: '50mb' }));

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Resume HTML to PDF Converter API',
    version: '1.0.0',
    endpoints: ['/convert-to-pdf'],
    configOptions: {
      format: ['A4', 'A3', 'A5', 'Letter', 'Legal', 'Tabloid'],
      margin: 'Object with top, right, bottom, left in px/cm/in',
      scale: 'Number between 0.1 and 2',
      landscape: 'Boolean',
      printBackground: 'Boolean',
      preferCSSPageSize: 'Boolean',
      displayHeaderFooter: 'Boolean',
      headerTemplate: 'HTML string',
      footerTemplate: 'HTML string',
      pageRanges: 'String (e.g., "1-5, 8")'
    }
  });
});

app.post('/convert-to-pdf', async (req, res) => {
  const { html, config = {} } = req.body;
  
  if (!html) {
    return res.status(400).json({ error: 'HTML content is required' });
  }

  // Merge default config with user config
  const pdfConfig = {
    ...DEFAULT_CONFIG,
    ...config,
    margin: {
      ...DEFAULT_CONFIG.margin,
      ...(config.margin || {})
    }
  };

  // Validate config
  if (pdfConfig.scale && (pdfConfig.scale < 0.1 || pdfConfig.scale > 2)) {
    return res.status(400).json({ error: 'Scale must be between 0.1 and 2' });
  }

  let browser;
  let tempHtmlPath;
  let tempPdfPath;

  try {
    // Create temporary files
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'resume-'));
    tempHtmlPath = path.join(tempDir, 'input.html');
    tempPdfPath = path.join(tempDir, 'output.pdf');

    // Write HTML to temp file
    await fs.writeFile(tempHtmlPath, html, 'utf8');

    // Launch browser and create PDF
    browser = await chromium.launch({
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();
    await page.goto(`file://${tempHtmlPath}`);

    // Generate PDF with user config
    await page.pdf({
      path: tempPdfPath,
      ...pdfConfig
    });

    // Read PDF file
    const pdfBuffer = await fs.readFile(tempPdfPath);

    // Set response headers
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=resume.pdf');

    // Send PDF
    res.send(pdfBuffer);

  } catch (error) {
    console.error('PDF generation error:', error);
    res.status(500).json({ 
      error: 'Failed to generate PDF',
      details: error.message
    });

  } finally {
    // Cleanup
    try {
      if (browser) await browser.close();
      if (tempHtmlPath) await fs.unlink(tempHtmlPath).catch(() => {});
      if (tempPdfPath) await fs.unlink(tempPdfPath).catch(() => {});
    } catch (error) {
      console.error('Cleanup error:', error);
    }
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Something broke!',
    details: err.message
  });
});

// Start server based on environment
const startServer = async () => {
  if (isProduction) {
    try {
      // Only try to read SSL certificates in production
      const privateKey = await fs.readFile(process.env.SSL_PRIVATE_KEY, 'utf8');
      const certificate = await fs.readFile(process.env.SSL_CERTIFICATE, 'utf8');
      
      const credentials = {
        key: privateKey,
        cert: certificate
      };

      // Create HTTPS server
      const httpsServer = https.createServer(credentials, app);
      
      httpsServer.listen(httpsPort, () => {
        console.log(`HTTPS Server running on https://${domain}:${httpsPort}`);
      });

      // Redirect HTTP to HTTPS in production
      const httpApp = express();
      httpApp.use((req, res) => {
        res.redirect(`https://${req.headers.host}${req.url}`);
      });
      
      http.createServer(httpApp).listen(port, () => {
        console.log(`HTTP redirect server running on http://${domain}:${port}`);
      });

    } catch (error) {
      console.error('Failed to start HTTPS server:', error);
      process.exit(1);
    }
  } else {
    // Development environment - use HTTP only
    app.listen(port, () => {
      console.log(`Development server running on http://${domain}:${port}`);
      console.log('SSL/HTTPS is disabled in development mode');
    });
  }
};

// Start the server
startServer().catch(error => {
  console.error('Failed to start server:', error);
  process.exit(1);
}); 