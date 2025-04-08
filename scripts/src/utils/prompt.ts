/**
 * Prompt the user with a question and return their input.
 */
export async function question(promptText: string): Promise<string> {
  process.stdout.write(promptText);

  const decoder = new TextDecoder();
  const inputChunks: Uint8Array[] = [];

  for await (const chunk of Bun.stdin.stream()) {
    inputChunks.push(chunk);
    if (chunk.includes(10)) break; // newline character
  }

  const input = decoder.decode(Uint8Array.from(inputChunks.flat()));
  return input.replace(/\r?\n$/, '');
}