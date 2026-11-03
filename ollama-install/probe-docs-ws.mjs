import { createDocumentsMemorySource } from 'file:///C:/Users/XYD/.dsh/profiles/desktop/node_modules/dsh-mnemon-source-documents/lib/index.js';
import fs from 'node:fs';

const reg = JSON.parse(fs.readFileSync(String.raw`C:\Users\XYD\.dsh\storages\workspace.json`, 'utf8'));
const list = reg.workspaces ?? reg.items ?? reg.units ?? [];
console.log('registry keys:', Object.keys(reg).join(','), '| count:', list.length);

const src = createDocumentsMemorySource();
const inst = src.create({ configuration: {}, sourceInstanceKey: 'source:include:mnemon-source-documents' });
const budget = { maxCharacters: 6000, maxTokens: 2000, maxResults: 10 };

for (const w of list) {
  const id = String(w.id ?? w.workspaceId ?? '');
  const p = String(w.path ?? w.root ?? w.directory ?? '');
  const out = [];
  for (const cand of [p, id]) {
    if (!cand) continue;
    try {
      const f = await inst.facts({ scope: { workspaceId: cand }, scenario: 'management.read', budget });
      out.push(`OK(${cand === p ? 'path' : 'id'})=${f.availability}`);
    } catch (e) {
      out.push(`THROW(${cand === p ? 'path' : 'id'})=${e.message.slice(0, 90)}`);
    }
  }
  console.log(`${id.slice(0, 8)}  ${out.join('  ')}  | ${p}`);
}
