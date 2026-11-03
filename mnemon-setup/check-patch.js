const yaml = require('js-yaml');
const fs = require('fs');
const p = 'C:/Users/XYD/.dsh/profiles/desktop/cordis.patch.yml';
const doc = yaml.load(fs.readFileSync(p, 'utf8'));
const s = JSON.stringify(doc, null, 1);
const i = s.indexOf('"include:mnemon-strategy-scoped"');
if (i < 0) { console.log('block not found'); process.exit(1); }
console.log(s.slice(i, i + 700));
