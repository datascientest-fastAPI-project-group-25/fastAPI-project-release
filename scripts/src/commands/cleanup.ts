import { execCommand } from '../utils/shell';
import { logger } from '../utils/logger';

async function cleanupEnvironment(env: string) {
  logger.info(`Cleaning up resources in fastapi-${env} namespace...`);
  await execCommand(`kubectl delete namespace fastapi-${env} --ignore-not-found`);
  logger.success(`Cleanup of ${env} environment complete!`);
}

async function main() {
  const arg = Bun.argv[2];
  if (!arg || !['dev', 'prod', 'all'].includes(arg)) {
    console.error("Usage: bun run cleanup.ts [dev|prod|all]");
    process.exit(1);
  }

  if (arg === 'dev' || arg === 'all') {
    await cleanupEnvironment('dev');
  }
  if (arg === 'prod' || arg === 'all') {
    await cleanupEnvironment('prod');
  }
}

main();