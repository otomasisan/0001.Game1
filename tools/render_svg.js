// art/src/*.svg を Chromium で PNG に書き出す(SVG のにじみ・紙の質感フィルタは Godot では描けないため)
// 使い方: node tools/render_svg.js <入力.svg> <出力.png> [幅] [高さ]
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
(async () => {
  const [src, out, w, h] = process.argv.slice(2);
  const svg = fs.readFileSync(src, 'utf8');
  const width = parseInt(w || (svg.match(/width="(\d+)"/) || [])[1] || '1920');
  const height = parseInt(h || (svg.match(/height="(\d+)"/) || [])[1] || '1080');
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 });
  await page.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  await page.locator('svg').screenshot({ path: out, omitBackground: true });
  await browser.close();
  console.log('wrote', out, width + 'x' + height);
})();
