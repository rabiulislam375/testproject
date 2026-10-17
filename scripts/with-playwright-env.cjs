const { spawnSync } = require('child_process');

const cli = require.resolve('@playwright/test/cli');
const env = { ...process.env };
delete env.NO_COLOR;
delete env.FORCE_COLOR;

const pwArgs = process.argv.slice(2);
const result = spawnSync(process.execPath, [cli, ...pwArgs], {
  stdio: 'inherit',
  env,
  windowsHide: true,
});

process.exit(result.status === null ? 1 : result.status);
