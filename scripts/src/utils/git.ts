/**
 * Normalize a branch name:
 * - Lowercase
 * - Replace spaces and underscores with hyphens
 * - Remove invalid characters
 * - Collapse multiple hyphens
 * - Trim leading/trailing hyphens
 */
export function normalizeBranchName(input: string): string {
  return input
    .toLowerCase()
    .replace(/[ _]+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');
}