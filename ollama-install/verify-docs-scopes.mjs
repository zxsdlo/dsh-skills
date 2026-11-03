import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { createDocumentsMemorySource } from 'file:///C:/Users/XYD/.dsh/profiles/desktop/node_modules/dsh-mnemon-source-documents/lib/index.js';

const inst = createDocumentsMemorySource().create({
  configuration: {},
  sourceInstanceKey: 'source:include:mnemon-source-documents',
});
const budget = { maxCharacters: 6000, maxTokens: 2000, maxResults: 10 };

const targets = new Map();
const reg = JSON.parse(fs.readFileSync(String.raw`C:\Users\XYD\.dsh\storages\workspace.json`, 'utf8'));
for (const [id, row] of Object.entries(reg.tables.workspaces ?? {})) targets.set(row.path, `workspace ${id.slice(0, 8)}`);

const root = String.raw`C:\Users\XYD\.dsh\sessions`;
for (const dir of fs.readdirSync(root)) {
  const p = path.join(root, dir);
  if (!fs.statSync(p).isDirectory()) continue;
  for (const sid of fs.readdirSync(p)) {
    const f = path.join(p, sid, 'session.v4.jsonl.zstd');
    if (!fs.existsSync(f)) continue;
    try {
      const head = zlib.zstdDecompressSync(fs.readFileSync(f)).toString('utf8').split('\n')[0];
      const meta = JSON.parse(head);
      if (meta.type === 'session' && meta.cwd && !targets.has(meta.cwd)) targets.set(meta.cwd, 'session cwd');
    } catch { /* ignore */ }
  }
}

let bad = 0;
for (const [ws, tag] of targets) {
  try {
    const f = await inst.facts({ scope: { workspaceId: ws }, scenario: 'management.read', budget });
    console.log(`OK    ${f.availability.padEnd(12)} ${tag} | ${ws}`);
  } catch (e) {
    bad++;
    console.log(`THROW ${e.message.slice(0, 80)} | ${ws}`);
  }
}
console.log(bad === 0 ? 'ALL READY' : `FAILED ${bad}`);
