from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from pydantic import BaseModel
from playwright.async_api import async_playwright
import tempfile
import os

app = FastAPI(title="Resume HTML to PDF Converter")

class HTMLContent(BaseModel):
    html: str

def cleanup_files(html_path: str, pdf_path: str):
    try:
        if os.path.exists(html_path):
            os.unlink(html_path)
        if os.path.exists(pdf_path):
            os.unlink(pdf_path)
    except Exception as e:
        print(f"Cleanup error: {e}")

@app.post("/convert-to-pdf")
async def convert_to_pdf(content: HTMLContent, background_tasks: BackgroundTasks):
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

        # Add cleanup to background tasks
        background_tasks.add_task(cleanup_files, html_path, pdf_path)

        # Return the PDF file
        return FileResponse(
            pdf_path,
            media_type='application/pdf',
            filename='resume.pdf'
        )

    except Exception as e:
        # Clean up files if there's an error
        cleanup_files(html_path, pdf_path)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def read_root():
    return {"message": "Resume HTML to PDF Converter API", "endpoints": ["/convert-to-pdf"]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 