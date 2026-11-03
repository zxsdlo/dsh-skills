import fs from 'node:fs';

const d = String.raw`C:\Users\XYD\Downloads\ppt-master-install`;
try {
  fs.mkdirSync(d, { recursive: true });
  console.log('mkdir', d, '->', fs.statSync(d).isDirectory());
} catch (e) {
  console.log('ERR', e.code, e.message);
}
