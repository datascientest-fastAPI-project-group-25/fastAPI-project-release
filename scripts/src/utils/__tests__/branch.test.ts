import { test, expect, mock } from 'bun:test';
import { normalizeBranchName, formatBranchName, promptBranchConfig, BranchConfig } from '../branch';
import { question } from '../prompt';

// Mock the prompt module
const mockQuestion = mock(() => {});
mock.module('../prompt', () => ({
  question: mockQuestion,
}));

test('normalizeBranchName handles various input formats', () => {
  const cases = [
    { input: 'My Feature Branch', expected: 'my-feature-branch' },
    { input: 'Fix_Bug#42!', expected: 'fix-bug42' },
    { input: '  --My__Crazy__Branch--  ', expected: 'my-crazy-branch' },
    { input: 'ALLCAPS', expected: 'allcaps' },
    { input: 'snake_case_name', expected: 'snake-case-name' },
    { input: 'multi   space', expected: 'multi-space' },
    { input: 'special*&^%$#@!', expected: 'special' },
    { input: '---trim---', expected: 'trim' },
    { input: 'dots.in.name', expected: 'dots-in-name' },
    { input: 'multiple___separators...mixed', expected: 'multiple-separators-mixed' },
  ];

  cases.forEach(({ input, expected }) => {
    expect(normalizeBranchName(input)).toBe(expected);
  });
});

test('formatBranchName generates correct branch names', () => {
  const cases: { config: BranchConfig; expected: string }[] = [
    {
      config: { type: 'feat', name: 'new-feature', breaking: false },
      expected: 'feat/new-feature'
    },
    {
      config: { type: 'feat', name: 'breaking-change', breaking: true },
      expected: 'feat/!breaking-change'
    },
    {
      config: { type: 'fix', name: 'bug-fix', breaking: false },
      expected: 'fix/bug-fix'
    },
    {
      config: { type: 'hotfix', name: 'urgent-fix', breaking: false },
      expected: 'hotfix/urgent-fix'
    },
    {
      config: { type: 'chore', name: 'update-deps', breaking: false },
      expected: 'chore/update-deps'
    },
  ];

  cases.forEach(({ config, expected }) => {
    expect(formatBranchName(config)).toBe(expected);
  });
});

test('promptBranchConfig handles interactive input correctly', async () => {
  const mockQuestion = mock(() => Promise.resolve(''));

  // Test feature branch with breaking change
  mockQuestion
    .mockResolvedValueOnce('feat')
    .mockResolvedValueOnce('New Feature Name')
    .mockResolvedValueOnce('y');

  let result = await promptBranchConfig();
  expect(result).toEqual({
    type: 'feat',
    name: 'new-feature-name',
    breaking: true
  });

  // Test fix branch (no breaking change prompt)
  mockQuestion
    .mockResolvedValueOnce('fix')
    .mockResolvedValueOnce('Bug Fix Name');

  result = await promptBranchConfig();
  expect(result).toEqual({
    type: 'fix',
    name: 'bug-fix-name',
    breaking: false
  });

  // Test invalid then valid type
  mockQuestion
    .mockResolvedValueOnce('invalid')
    .mockResolvedValueOnce('chore')
    .mockResolvedValueOnce('Update Dependencies');

  result = await promptBranchConfig();
  expect(result).toEqual({
    type: 'chore',
    name: 'update-dependencies',
    breaking: false
  });
});