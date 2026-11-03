import fs from 'node:fs';

const bogus = [
  String.raw`D:\百度网盘下载文件\DeepSeek Harness的工作区\插件skills和软件安装与配置\DeepSeek Harness插件和软件安装与配置`,
  String.raw`D:\百度网盘下载文件\DeepSeek Harness的工作区\插件skills和软件安装与配置\DeepSeek Harness软件自检`,
];
for (const d of bogus) {
  try {
    const rows = fs.readdirSync(d);
    if (rows.length > 0) {
      console.log('SKIP non-empty', d, rows.length);
      continue;
    }
    fs.rmdirSync(d);
    console.log('removed bogus', d, '-> exists=', fs.existsSync(d));
  } catch (e) {
    console.log('ERR remove', d, e.code, e.message);
  }
}

const targets = [
  String.raw`D:\DeepSeek Harness\插件和软件安装与配置`,
  String.raw`D:\DeepSeek Harness\软件自检`,
];
for (const d of targets) {
  try {
    fs.mkdirSync(d, { recursive: true });
    console.log('mkdir', d, '->', fs.statSync(d).isDirectory());
  } catch (e) {
    console.log('ERR mkdir', d, e.code, e.message);
  }
}
