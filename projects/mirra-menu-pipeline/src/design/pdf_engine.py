"""PDF Engine — Playwright HTML→PDF renderer."""

import asyncio
from pathlib import Path


class MirraPDFEngine:
    """Playwright-powered HTML→PDF renderer matching Mirra brand."""

    async def render(self, html_content: str, output_path: str) -> str:
        """Generate PDF from HTML using headless Chromium."""
        from playwright.async_api import async_playwright

        async with async_playwright() as p:
            browser = await p.chromium.launch()
            page = await browser.new_page()
            
            # Set content and wait for fonts
            await page.set_content(html_content)
            await page.wait_for_load_state("networkidle")
            # Extra wait for font rendering
            await page.wait_for_timeout(1000)

            await page.pdf(
                path=output_path,
                width="1080px",
                height="1350px",
                print_background=True,
                margin={"top": "0", "right": "0", "bottom": "0", "left": "0"},
                scale=1.0,
            )
            await browser.close()

        # Verify
        p = Path(output_path)
        if not p.exists() or p.stat().st_size == 0:
            raise RuntimeError(f"PDF generation failed: {output_path}")
        
        print(f"  PDF saved: {output_path} ({p.stat().st_size / 1024:.0f} KB)")
        return output_path

    def render_sync(self, html_content: str, output_path: str) -> str:
        """Synchronous wrapper."""
        return asyncio.get_event_loop().run_until_complete(
            self.render(html_content, output_path)
        )
