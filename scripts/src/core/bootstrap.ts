import { platform } from './platform';
import { logger } from '../utils/logger';
import { execCommand } from '../utils/shell';

interface Environment {
  bunVersion: string;
  nodeVersion?: string;
  gitVersion: string;
  kubectlVersion?: string;
}

async function detectEnvironment(): Promise<Environment> {
  const bunVersion = (await execCommand('bun --version')).stdout.trim();
  const gitVersion = (await execCommand('git --version')).stdout.trim();

  const env: Environment = {
    bunVersion,
    gitVersion
  };

  const nodeCheck = await execCommand('node --version');
  if (nodeCheck.success) {
    env.nodeVersion = nodeCheck.stdout.trim();
  }

  const kubeCheck = await execCommand('kubectl version --client --short');
  if (kubeCheck.success) {
    env.kubectlVersion = kubeCheck.stdout.trim();
  }

  return env;
}

export async function bootstrap(): Promise<void> {
  logger.info('Starting environment bootstrap...');

  if (!platform.isSupported) {
    logger.error('Unsupported platform');
    process.exit(1);
  }

  const env = await detectEnvironment();
  logger.info(`Detected Bun: ${env.bunVersion}`);
  logger.info(`Detected Git: ${env.gitVersion}`);
  if (env.nodeVersion) logger.info(`Detected Node.js: ${env.nodeVersion}`);
  if (env.kubectlVersion) logger.info(`Detected kubectl: ${env.kubectlVersion}`);

  logger.success('Bootstrap complete!');
}

if (import.meta.main) {
  bootstrap().catch(err => {
    logger.error(`Bootstrap failed: ${err.message}`);
    process.exit(1);
  });
}