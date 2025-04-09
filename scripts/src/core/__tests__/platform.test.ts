/* @ts-ignore */
import { test, expect } from "bun:test";
import { platform } from '../platform';

test('platform info matches current platform', () => {
  const detected = process.platform;
  if (detected === 'darwin') expect(platform.isMac).toBe(true);
  if (detected === 'linux') expect(platform.isLinux).toBe(true);
  if (detected === 'win32') expect(platform.isWindows).toBe(true);
  expect(platform.isSupported).toBe(true);
});