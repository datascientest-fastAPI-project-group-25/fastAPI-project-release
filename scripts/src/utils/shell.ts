export interface ShellResult {
  success: boolean;
  stdout: string;
  stderr: string;
  code: number;
}

export async function execCommand(command: string): Promise<ShellResult> {
  const proc = Bun.spawn(['sh', '-c', command], {
    stdout: 'pipe',
    stderr: 'pipe'
  });

  const stdoutPromise = new Response(proc.stdout).text();
  const stderrPromise = new Response(proc.stderr).text();

  // Wait for process to exit
  const exitCode = await proc.exited;
  const stdout = await stdoutPromise;
  const stderr = await stderrPromise;

  return {
    success: exitCode === 0,
    stdout,
    stderr,
    code: exitCode
  };
}