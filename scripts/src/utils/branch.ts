import { promptBranchType, promptBranchName, promptIsBreaking } from './interactivePrompt';

export type BranchType = 'feat' | 'fix' | 'hotfix' | 'chore';

export interface BranchConfig {
  type: BranchType;
  name: string;
  breaking?: boolean;
}

/**
 * Normalize a branch name to kebab-case format:
 * - Convert to lowercase
 * - Replace spaces, underscores, and dots with hyphens
 * - Remove special characters
 * - Collapse multiple hyphens
 * - Trim leading/trailing hyphens
 */
export function normalizeBranchName(input: string): string {
  return input
    .toLowerCase()
    .replace(/[\s_\.]+/g, '-') // Convert spaces, underscores, and dots to hyphens
    .replace(/[^a-z0-9-]/g, '') // Remove special characters
    .replace(/-+/g, '-') // Collapse multiple hyphens
    .replace(/^-+|-+$/g, ''); // Trim leading/trailing hyphens
}

/**
 * Interactive branch configuration prompt
 */
export async function promptBranchConfig(): Promise<BranchConfig> {
  // Get branch type using interactive prompt
  const type = await promptBranchType();

  // Get branch name using interactive prompt
  const rawName = await promptBranchName();
  const name = normalizeBranchName(rawName);

  // For feature branches, ask about breaking changes using interactive prompt
  const breaking = type === 'feat' ? await promptIsBreaking() : false;

  return {
    type: type as BranchType, // Explicitly cast type to BranchType
    name,
    breaking
  };
}
/**
 * Format branch name according to convention
 */
export function formatBranchName(config: BranchConfig): string {
  const { type, name, breaking } = config;
  const prefix = breaking ? `${type}/!` : `${type}/`;
  return `${prefix}${name}`;
}