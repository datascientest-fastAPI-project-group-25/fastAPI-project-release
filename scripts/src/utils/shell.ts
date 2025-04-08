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
  
  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();
  
  return {
    success: proc.exitCode === 0,
    stdout,
    stderr,
    code: proc.exitCode ?? -1
  };
}