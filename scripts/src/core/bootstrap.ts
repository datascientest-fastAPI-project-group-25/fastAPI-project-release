import { platform } from './platform';
import { logger } from '../utils/logger';
import { execCommand } from '../utils/shell';

interface Environment {
  bunVersion?: string;
  nodeVersion?: string;
  gitVersion?: string;
  dockerVersion?: string;
  kubectlVersion?: string;
  k3dVersion?: string;
  helmVersion?: string;
}

interface Tool {
  name: string;
  versionCommand: string;
  versionExtractor?: (output: string) => string;
  installInstructions: {
    mac: string;
    linux: string;
    windows: string;
  };
  required: boolean;
}

const REQUIRED_TOOLS: Tool[] = [
  {
    name: 'bun',
    versionCommand: 'bun --version',
    versionExtractor: (output: string) => output.trim(),
    installInstructions: {
      mac: 'curl -fsSL https://bun.sh/install | bash',
      linux: 'curl -fsSL https://bun.sh/install | bash',
      windows: 'Visit https://bun.sh/install for Windows installation instructions'
    },
    required: true
  },
  {
    name: 'git',
    versionCommand: 'git version',
    versionExtractor: (output: string) => output.replace('git version', '').trim(),
    installInstructions: {
      mac: 'brew install git',
      linux: 'sudo apt-get update && sudo apt-get install git',
      windows: 'https://git-scm.com/download/win'
    },
    required: true
  },
  {
    name: 'docker',
    versionCommand: 'docker version --format "{{.Client.Version}}"',
    installInstructions: {
      mac: 'Visit https://docs.docker.com/desktop/install/mac-install/',
      linux: 'Visit https://docs.docker.com/engine/install/',
      windows: 'Visit https://docs.docker.com/desktop/install/windows-install/'
    },
    required: true
  },
  {
    name: 'kubectl',
    versionCommand: 'kubectl version --client -o json',
    versionExtractor: (output: string) => {
      try {
        const data = JSON.parse(output);
        return data.clientVersion?.gitVersion || data.kustomizeVersion || output.trim();
      } catch {
        return output.trim();
      }
    },
    installInstructions: {
      mac: 'brew install kubectl',
      linux: 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/',
      windows: 'Visit https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/'
    },
    required: true
  },
  {
    name: 'k3d',
    versionCommand: 'k3d version -o json',
    versionExtractor: (output: string) => {
      try {
        const data = JSON.parse(output);
        return data.version || output.trim();
      } catch {
        // Fallback to simple version output if JSON parsing fails
        return output.split('\n')[0].trim();
      }
    },
    installInstructions: {
      mac: 'brew install k3d',
      linux: 'curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash',
      windows: 'choco install k3d'
    },
    required: true
  },
  {
    name: 'helm',
    versionCommand: 'helm version --template "{{.Version}}"',
    versionExtractor: (output: string) => output.trim().replace(/^v/, ''),
    installInstructions: {
      mac: 'brew install helm',
      linux: 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash',
      windows: 'choco install kubernetes-helm'
    },
    required: true
  },
  {
    name: 'node',
    versionCommand: 'node --version',
    versionExtractor: (output: string) => output.trim().replace(/^v/, ''),
    installInstructions: {
      mac: 'brew install node',
      linux: 'curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs',
      windows: 'Visit https://nodejs.org/en/download/'
    },
    required: false
  }
];

async function checkTool(tool: Tool): Promise<string | undefined> {
  // Common paths where tools might be installed
  const commonPaths = [
    '/usr/local/bin',
    '/usr/bin',
    '/bin',
    '/opt/homebrew/bin', // Homebrew on Apple Silicon
    '/usr/local/homebrew/bin', // Homebrew on Intel Mac
    `${process.env.HOME}/.docker/bin`, // Docker CLI
    `${process.env.HOME}/.krew/bin`, // kubectl plugins
    '/Applications/Docker.app/Contents/Resources/bin', // Docker Desktop
  ];

  // Add PATH environment variable paths
  if (process.env.PATH) {
    commonPaths.push(...process.env.PATH.split(':'));
  }

  // Create a unique set of paths
  const uniquePaths = Array.from(new Set(commonPaths));

  try {
    // First try with current PATH
    const result = await execCommand(tool.versionCommand);
    if (result.success) {
      const version = tool.versionExtractor
        ? tool.versionExtractor(result.stdout.trim())
        : result.stdout.trim();
      return version;
    }

    // If not found, try with each additional path
    for (const path of uniquePaths) {
      try {
        const result = await execCommand(`${path}/${tool.name} --version`);
        if (result.success) {
          const version = tool.versionExtractor
            ? tool.versionExtractor(result.stdout.trim())
            : result.stdout.trim();

          // If found, suggest adding to PATH
          logger.warn(`${tool.name} was found in ${path} but isn't in your PATH`);
          logger.info(`Add to your shell profile (~/.zshrc, ~/.bashrc, etc.):`);
          logger.info(`  export PATH="${path}:$PATH"`);

          return version;
        }
      } catch (error) {
        // Continue trying other paths
        continue;
      }
    }
  } catch (error) {
    // Tool not found in any location
  }
  return undefined;
}

async function detectEnvironment(): Promise<Environment> {
  const env: Environment = {};

  for (const tool of REQUIRED_TOOLS) {
    const version = await checkTool(tool);
    const envKey = `${tool.name}Version` as keyof Environment;
    env[envKey] = version;
  }

  return env;
}

function getInstallInstructions(tool: Tool): string {
  let instructions = '';
  if (platform.isMac) {
    instructions = tool.installInstructions.mac;
  } else if (platform.isLinux) {
    instructions = tool.installInstructions.linux;
  } else if (platform.isWindows) {
    instructions = tool.installInstructions.windows;
  }
  return instructions;
}

export async function bootstrap(): Promise<void> {
  logger.info('Starting environment bootstrap...');

  if (!platform.isSupported) {
    logger.error('Unsupported platform');
    process.exit(1);
  }

  const env = await detectEnvironment();
  let missingRequired = false;
  let foundSomeOptional = false;

  console.log(); // Empty line for better readability
  logger.info('=== Environment Check ===');

  // Group tools by status for better output organization
  const requiredTools = REQUIRED_TOOLS.filter(t => t.required);
  const optionalTools = REQUIRED_TOOLS.filter(t => !t.required);

  // Check required tools first
  logger.info('Required Tools:');
  for (const tool of requiredTools) {
    const version = env[`${tool.name}Version` as keyof Environment];
    if (version) {
      logger.success(`✓ ${tool.name}: ${version}`);
    } else {
      missingRequired = true;
      logger.error(`✗ ${tool.name}: Not found`);
      const instructions = getInstallInstructions(tool);
      logger.info(`  Installation instructions:`);
      logger.info(`  ${instructions}`);
    }
  }

  console.log(); // Empty line for better readability

  // Check optional tools
  if (optionalTools.length > 0) {
    logger.info('Optional Tools:');
    for (const tool of optionalTools) {
      const version = env[`${tool.name}Version` as keyof Environment];
      if (version) {
        logger.success(`✓ ${tool.name}: ${version}`);
        foundSomeOptional = true;
      } else {
        logger.warn(`? ${tool.name}: Not found (optional)`);
      }
    }
    console.log(); // Empty line for better readability
  }

  if (missingRequired) {
    logger.error('❌ Some required tools are missing!');
    logger.info('Please install the missing required tools and run this command again.');
    if (platform.isMac) {
      logger.info('For Homebrew users on macOS, you can install all required tools with:');
      logger.info('  brew install git docker kubectl k3d helm');
    }
    console.log();
    logger.info('For other installation methods, follow the instructions above for each tool.');
    process.exit(1);
  } else {
    logger.success('✅ All required tools are installed!');
    if (optionalTools.length > 0 && !foundSomeOptional) {
      logger.info('Consider installing optional tools for enhanced development experience.');
    }
    logger.info('You can now proceed with development.');
  }
}

if (import.meta.main) {
  bootstrap().catch(err => {
    logger.error(`Bootstrap failed: ${err.message}`);
    process.exit(1);
  });
}