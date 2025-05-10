import { logger } from '../../utils/logger';
import { execCommand } from '../../utils/shell';
import { promptBranchConfig, normalizeBranchName, formatBranchName, BranchConfig } from '../../utils/branch';

async function main() {
  const args = Bun.argv.slice(2);
  let config: BranchConfig;

  if (args.length === 0) {
    // Interactive mode
    config = await promptBranchConfig();
  } else {
    // Command line mode
    const type = args[0];
    if (!['feat', 'fix', 'hotfix', 'chore'].includes(type)) {
      logger.error('Invalid branch type. Must be one of: feat, fix, hotfix, chore');
      process.exit(1);
    }

    const name = args.slice(1).join(' ');
    if (!name) {
      logger.error('Branch name is required');
      process.exit(1);
    }

    config = {
      type: type as BranchConfig['type'],
      name: normalizeBranchName(name),
      breaking: false
    };
  }

  const branchName = formatBranchName(config);
  logger.info(`Creating and switching to branch: ${branchName}`);

  const { success, stderr } = await execCommand(`git checkout -b ${branchName}`);
  if (!success) {
    logger.error(stderr);
    process.exit(1);
  }

  logger.success(`Successfully created and switched to branch: ${branchName}`);
}

main();