import { test, expect, mock } from 'bun:test';
import { select, input, confirm } from '@inquirer/prompts';
import { promptBranchType, promptBranchName, promptIsBreaking } from '../interactivePrompt';

// Mock inquirer prompts
mock.module('@inquirer/prompts', () => ({
  select: mock(() => Promise.resolve('feat')),
  input: mock(() => Promise.resolve('test-branch')),
  confirm: mock(() => Promise.resolve(false))
}));

test('promptBranchType returns valid branch type', async () => {
  const type = await promptBranchType();
  expect(type).toBe('feat');
  expect(select).toHaveBeenCalled();
});

test('promptBranchName returns normalized branch name', async () => {
  const name = await promptBranchName();
  expect(name).toBe('test-branch');
  expect(input).toHaveBeenCalled();
});

test('promptIsBreaking returns boolean for breaking change', async () => {
  const isBreaking = await promptIsBreaking();
  expect(typeof isBreaking).toBe('boolean');
  expect(isBreaking).toBe(false);
  expect(confirm).toHaveBeenCalled();
});