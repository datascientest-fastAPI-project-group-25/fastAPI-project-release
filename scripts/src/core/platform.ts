export interface PlatformInfo {
  isWindows: boolean;
  isMac: boolean;
  isLinux: boolean;
  isSupported: boolean;
  shell: string;
  pathSeparator: string;
}

export const platform: PlatformInfo = {
  isWindows: process.platform === 'win32',
  isMac: process.platform === 'darwin',
  isLinux: process.platform === 'linux',
  isSupported: ['darwin', 'linux', 'win32'].includes(process.platform),
  shell: process.platform === 'win32' ? 'cmd.exe' : 'sh',
  pathSeparator: process.platform === 'win32' ? '\\' : '/'
};