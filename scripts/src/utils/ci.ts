// scripts-next/src/utils/ci.ts

/**
 * Detects if the script is running in a known CI environment.
 * Checks for common CI environment variables.
 */
export function isCI(): boolean {
    return !!(
        process.env.CI ||
        process.env.GITHUB_ACTIONS ||
        process.env.GITLAB_CI ||
        process.env.TRAVIS ||
        process.env.JENKINS_URL
    );
}