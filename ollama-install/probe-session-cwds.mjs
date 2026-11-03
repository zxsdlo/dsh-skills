import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const root = String.raw`C:\Users\XYD\.dsh\sessions`;
const byCwd = new Map();
for (const dir of fs.readdirSync(root)) {
  const p = path.join(root, dir);
  if (!fs.statSync(p).isDirectory()) continue;
  for (const sid of fs.readdirSync(p)) {
    const f = path.join(p, sid, 'session.v4.jsonl.zstd');
    if (!fs.existsSync(f)) continue;
    let head = '';
    try {
      head = zlib.zstdDecompressSync(fs.readFileSync(f, 'utf8' ? f : f).subarray(0, 1e9)).toString('utf8').split('\n')[0];
    } catch {
      try {
        const buf = fs.readFileSync(f);
        head = zlib.zstdDecompressSync(buf).toString('utf8').split('\n')[0];
      } catch { continue; }
    }
    let meta;
    try { meta = JSON.parse(head); } catch { continue; }
    if (meta.type !== 'session' || !meta.cwd) continue;
    const e = byCwd.get(meta.cwd) ?? { count: 0, last: 0, sample: sid };
    e.count++;
    e.last = Math.max(e.last, fs.statSync(f).mtimeMs);
    byCwd.set(meta.cwd, e);
  }
}

for (const [cwd, e] of [...byCwd].sort((a, b) => b[1].last - a[1].last)) {
  const ok = fs.existsSync(cwd) && fs.statSync(cwd).isDirectory();
  console.log(`${ok ? 'OK   ' : 'MISS '} ${String(e.count).padStart(3)} sessions | last ${new Date(e.last).toISOString()} | ${cwd}`);
}
