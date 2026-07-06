// Renders the Play feature graphic (1024x500) from featuregraphic.html.
// Usage: node graphic.js <pageUrl> <outFile>
const { chromium } = require('playwright');

const url = process.argv[2] || 'http://localhost:8787/featuregraphic.html';
const out = process.argv[3] || 'out/featureGraphic.png';

(async () => {
  const browser = await chromium.launch({ channel: 'chrome' });
  const page = await browser.newPage({
    viewport: { width: 1024, height: 500 },
    deviceScaleFactor: 1,
  });
  await page.goto(url, { waitUntil: 'networkidle' }).catch(() => {});
  await page.waitForTimeout(2500); // web fonts
  await page.screenshot({ path: out });
  await browser.close();
  console.log('feature graphic ->', out);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
