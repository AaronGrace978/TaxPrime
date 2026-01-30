const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const dir = __dirname;
const htmlPath = path.join(dir, 'index.html');
const pdfPath = path.join(dir, 'TaxPrime-PitchDeck.pdf');
const htmlUrl = 'file:///' + htmlPath.replace(/\\/g, '/');

(async () => {
  if (!fs.existsSync(htmlPath)) {
    console.error('index.html not found in', dir);
    process.exit(1);
  }
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.goto(htmlUrl, { waitUntil: 'networkidle0' });
  await page.pdf({
    path: pdfPath,
    format: 'A4',
    printBackground: true,
    margin: { top: '20mm', right: '20mm', bottom: '20mm', left: '20mm' },
    preferCSSPageSize: false,
  });
  await browser.close();
  console.log('PDF saved:', pdfPath);
})();
