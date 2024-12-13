from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import asyncio
from playwright.async_api import async_playwright
import tempfile
import os

app = FastAPI(title="Resume HTML to PDF Converter")

class HTMLContent(BaseModel):
    html: str

@app.post("/convert-to-pdf")
async def convert_to_pdf(content: HTMLContent):
    try:
        # Create a temporary file for the HTML
        with tempfile.NamedTemporaryFile(delete=False, suffix='.html', mode='w', encoding='utf-8') as html_file:
            html_file.write(content.html)
            html_path = html_file.name

        # Create a temporary file for the PDF
        pdf_path = html_path.replace('.html', '.pdf')

        async with async_playwright() as p:
            browser = await p.chromium.launch()
            page = await browser.new_page()
            
            # Load the HTML file
            await page.goto(f'file://{html_path}')
            
            # Generate PDF with text layer
            await page.pdf(path=pdf_path, format='A4')
            
            await browser.close()

        # Return the PDF file
        response = FileResponse(
            pdf_path,
            media_type='application/pdf',
            filename='resume.pdf'
        )

        # Clean up temporary files
        def cleanup():
            try:
                os.unlink(html_path)
                os.unlink(pdf_path)
            except:
                pass

        response.background = cleanup
        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def read_root():
    return {"message": "Resume HTML to PDF Converter API", "endpoints": ["/convert-to-pdf"]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 