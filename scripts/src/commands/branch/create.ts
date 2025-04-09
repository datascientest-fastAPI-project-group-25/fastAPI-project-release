import { normalizeBranchName } from '../../utils/git';
import { execCommand } from '../../utils/shell';
import { question } from '../../utils/prompt';
import { logger } from '../../utils/logger';

async function main() {
  const args = Bun.argv.slice(2);

  let prefix: string | undefined;
  let name: string | undefined;

  if (args.length >= 2) {
    prefix = args[0];
    name = args.slice(1).join(' ');
  } else if (args.length === 1) {
    prefix = args[0];
    name = (await question('Enter branch name: ')).trim();
  } else {
    let inputPrefix = '';
    while (!['feat', 'fix'].includes(inputPrefix)) {
      inputPrefix = (await question('Select branch type (feat/fix): ')).trim();
    }
    prefix = inputPrefix;
    name = (await question('Enter branch name: ')).trim();
  }

  if (!prefix || !name) {
    console.error('Prefix and branch name are required.');
    process.exit(1);
  }

  const normalized = normalizeBranchName(name);
  const branch = `${prefix}/${normalized}`;

  logger.info(`Creating and switching to branch: ${branch}`);
  const { success, stderr } = await execCommand(`git checkout -b ${branch}`);
  if (!success) {
    console.error(stderr);
    process.exit(1);
  }
}

main();