import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { chromium } from 'playwright';
import { dirname, join } from 'path';
import fs from 'fs/promises';
import os from 'os';

const app = express();
const port = process.env.PORT || 8000;

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
    endpoints: ['/convert-to-pdf']
  });
});

app.post('/convert-to-pdf', async (req, res) => {
  const { html } = req.body;
  
  if (!html) {
    return res.status(400).json({ error: 'HTML content is required' });
  }

  let browser;
  let tempHtmlPath;
  let tempPdfPath;

  try {
    // Create temporary files
    const tempDir = await fs.mkdtemp(join(os.tmpdir(), 'resume-'));
    tempHtmlPath = join(tempDir, 'input.html');
    tempPdfPath = join(tempDir, 'output.pdf');

    // Write HTML to temp file
    await fs.writeFile(tempHtmlPath, html, 'utf8');

    // Launch browser and create PDF
    browser = await chromium.launch({
      args: ['--no-sandbox', '--disable-setuid-sandbox'] // Required for running in Docker/Ubuntu
    });
    const page = await browser.newPage();
    await page.goto(`file://${tempHtmlPath}`);
    await page.pdf({
      path: tempPdfPath,
      format: 'A4',
      printBackground: true,
      margin: {
        top: '20px',
        right: '20px',
        bottom: '20px',
        left: '20px'
      }
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
    res.status(500).json({ error: 'Failed to generate PDF' });

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
  res.status(500).json({ error: 'Something broke!' });
});

// Start server
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
}); 