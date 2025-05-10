import { select, input, confirm } from '@inquirer/prompts';
import chalk from 'chalk';
import { BranchType } from './branch';

const BRANCH_TYPES: BranchType[] = ['feat', 'fix', 'hotfix', 'chore'];

export async function promptBranchType(): Promise<BranchType> {
  const type = await select({
    message: chalk.blue('Select branch type:'),
    choices: BRANCH_TYPES.map(type => ({
      name: type,
      value: type,
      description: getBranchTypeDescription(type)
    })),
    default: 'feat'
  });
  return type;
}

export async function promptBranchName(): Promise<string> {
  const name = await input({
    message: chalk.blue('Enter branch name:'),
    validate: (input: string) => {
      if (!input.trim()) {
        return chalk.red('Branch name cannot be empty');
      }
      return true;
    }
  });
  return name.trim();
}

export async function promptIsBreaking(): Promise<boolean> {
  const isBreaking = await confirm({
    message: chalk.yellow('Is this a breaking change?'),
    default: false
  });
  return isBreaking;
}

function getBranchTypeDescription(type: BranchType): string {
  const descriptions: Record<BranchType, string> = {
    feat: chalk.green('New feature development'),
    fix: chalk.yellow('Bug fix'),
    hotfix: chalk.red('Urgent production fix'),
    chore: chalk.gray('Maintenance tasks')
  };
  return descriptions[type];
}