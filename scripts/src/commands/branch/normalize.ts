import { normalizeBranchName } from '../../utils/git';

const input = Bun.argv.slice(2).join(' ').trim();

if (!input) {
  console.error('Usage: bun run normalize <branch-name>');
  process.exit(1);
}

console.log(normalizeBranchName(input));