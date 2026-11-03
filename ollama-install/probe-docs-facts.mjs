import { createDocumentsMemorySource } from 'file:///C:/Users/XYD/.dsh/profiles/desktop/node_modules/dsh-mnemon-source-documents/lib/index.js';

const src = createDocumentsMemorySource();
const inst = src.create({
  configuration: {},
  sourceInstanceKey: 'source:include:mnemon-source-documents',
});

const budget = { maxCharacters: 6000, maxTokens: 2000, maxResults: 10 };

const targets = [
  String.raw`D:\百度网盘下载文件\DeepSeek Harness的工作区\插件skills和软件安装与配置`,
  String.raw`D:\DeepSeek Harness\插件和软件安装与配置`,
  String.raw`D:\DeepSeek Harness\软件自检`,
  String.raw`C:\Users\XYD\Documents\deepseek-harness\default-workspace`,
];

for (const ws of targets) {
  try {
    const f = await inst.facts({ scope: { workspaceId: ws }, scenario: 'management.read', budget });
    console.log('OK    ', f.availability, f.revision, '|', ws);
  } catch (e) {
    console.log('THROW ', e.message, '|', ws);
  }
}
