/* @ts-ignore */
import { test, expect } from "bun:test";
import { normalizeBranchName } from '../../../utils/git';

const cases = [
  { input: 'My Feature Branch', expected: 'my-feature-branch' },
  { input: 'Fix_Bug#42!', expected: 'fix-bug42' },
  { input: '  --My__Crazy__Branch--  ', expected: 'my-crazy-branch' },
  { input: 'ALLCAPS', expected: 'allcaps' },
  { input: 'snake_case_name', expected: 'snake-case-name' },
  { input: 'multi   space', expected: 'multi-space' },
  { input: 'special*&^%$#@!', expected: 'special' },
  { input: '---trim---', expected: 'trim' },
];

cases.forEach(({ input, expected }) => {
  test(`normalizeBranchName("${input}") -> "${expected}"`, () => {
    expect(normalizeBranchName(input)).toBe(expected);
  });
});