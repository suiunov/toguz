// Copies the web game (../index.html etc.) into www/ for the Capacitor app.
// Changes for the app version only:
//  - fonts are bundled, so the game looks right with no internet
//  - no service worker and no "Install app" button (it already is an app)
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const www = path.join(__dirname, 'www');
fs.rmSync(www, { recursive: true, force: true });
fs.mkdirSync(path.join(www, 'fonts'), { recursive: true });

for (const f of ['manifest.json', 'icon-192.png', 'icon-512.png', 'icon-maskable-512.png', 'apple-touch-icon.png']) {
  fs.copyFileSync(path.join(root, f), path.join(www, f));
}

// Fonts: Rubik 400/500/700/800 + Philosopher 700, only woff2 files that are used.
const fontCss = [
  ['rubik', ['400', '500', '700', '800']],
  ['philosopher', ['700']],
].flatMap(([pkg, weights]) => weights.map(w => {
  const dir = path.join(__dirname, 'node_modules', '@fontsource', pkg);
  let css = fs.readFileSync(path.join(dir, `${w}.css`), 'utf8');
  css = css.replace(/, url\(\.\/files\/[^)]+\.woff\) format\('woff'\)/g, '');
  for (const m of css.matchAll(/url\(\.\/files\/([^)]+\.woff2)\)/g)) {
    fs.copyFileSync(path.join(dir, 'files', m[1]), path.join(www, 'fonts', m[1]));
  }
  return css.replace(/url\(\.\/files\//g, 'url(fonts/');
})).join('\n');
fs.writeFileSync(path.join(www, 'fonts.css'), fontCss);

let html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const swap = (from, to) => {
  if (!from.test(html)) throw new Error('build.js: could not find ' + from);
  html = html.replace(from, to);
};
swap(/<link rel="preconnect" href="https:\/\/fonts\.googleapis\.com">\s*/, '');
swap(/<link href="https:\/\/fonts\.googleapis\.com\/css2[^>]*>/, '<link rel="stylesheet" href="fonts.css">');
swap(/if\('serviceWorker' in navigator\)navigator\.serviceWorker\.register\('sw\.js'\)\.catch\(\(\)=>\{\}\);/, '');
swap(/<button class="mi" id="mInstall" hidden>/, '<button class="mi" id="mInstall" hidden style="display:none">');
fs.writeFileSync(path.join(www, 'index.html'), html);

console.log('www/ ready');
