import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const root = String.raw`C:\Users\XYD\.dsh\sessions`;
const rows = [];
for (const dir of fs.readdirSync(root)) {
  const p = path.join(root, dir);
  if (!fs.statSync(p).isDirectory()) continue;
  for (const sid of fs.readdirSync(p)) {
    const f = path.join(p, sid, 'session.v4.jsonl.zstd');
    if (!fs.existsSync(f)) continue;
    rows.push({ dir, sid, f, mtime: fs.statSync(f).mtimeMs });
  }
}
rows.sort((a, b) => b.mtime - a.mtime);
console.log('sessions:', rows.length);
for (const r of rows.slice(0, 6)) {
  let text = '';
  try {
    text = zlib.zstdDecompressSync(fs.readFileSync(r.f)).toString('utf8');
  } catch (e) {
    text = 'ERR ' + e.message;
  }
  const head = text.split('\n').slice(0, 2).join('\n');
  const ws = [...text.matchAll(/"workspaceId"\s*:\s*"([^"]+)"/g)].map((m) => m[1]);
  const wsSet = [...new Set(ws)];
  console.log('\n---', new Date(r.mtime).toISOString(), r.sid, '| dir:', r.dir);
  console.log('workspaceIds:', wsSet.slice(0, 5).join(', ') || '(none)');
  console.log('head:', head.slice(0, 300).replace(/\n/g, ' '));
}
