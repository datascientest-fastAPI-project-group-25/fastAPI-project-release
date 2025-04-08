/* @ts-ignore */
import { test, expect } from "bun:test";
import { logger } from '../logger';

test('logger.info outputs info prefix', () => {
  const original = console.log;
  const calls: any[] = [];
  console.log = (...args: any[]) => calls.push(args);

  logger.info('Hello');

  console.log = original;
  expect(calls.some(args => args[0].includes('ℹ') && args[1] === 'Hello')).toBe(true);
});

test('logger.warn outputs warn prefix', () => {
  const original2 = console.log;
  const calls2: any[] = [];
  console.log = (...args: any[]) => calls2.push(args);

  logger.warn('Warning');

  console.log = original2;
  expect(calls2.some(args => args[0].includes('⚠') && args[1] === 'Warning')).toBe(true);
});

test('logger.error outputs error prefix', () => {
  const original3 = console.error;
  const calls3: any[] = [];
  console.error = (...args: any[]) => calls3.push(args);

  logger.error('Error');

  console.error = original3;
  expect(calls3.some(args => args[0].includes('✖') && args[1] === 'Error')).toBe(true);
});

test('logger.success outputs success prefix', () => {
  const original4 = console.log;
  const calls4: any[] = [];
  console.log = (...args: any[]) => calls4.push(args);

  logger.success('Success');

  console.log = original4;
  expect(calls4.some(args => args[0].includes('✔') && args[1] === 'Success')).toBe(true);
});