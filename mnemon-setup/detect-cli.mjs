const mod = await import('file:///C:/Users/XYD/.dsh/profiles/desktop/node_modules/dsh-mnemon-source-memory-spaces/lib/native-cli.js');
const env = { ...process.env, PATH: 'C:/Users/XYD/AppData/Roaming/npm;C:/Windows/System32;C:/Program Files/nodejs' };
const found = mod.findMnemonCommand({}, { platform: 'win32', env, home: 'C:/Users/XYD' });
console.log('detected:', found);
if (found) console.log('launcher:', mod.mnemonNpmLauncher(found));
