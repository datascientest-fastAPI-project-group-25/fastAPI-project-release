import { execCommand } from '../../utils/shell';
import { logger } from '../../utils/logger';
import { question } from '../../utils/prompt';

async function checkInstalled(cmd: string): Promise<boolean> {
    const { success } = await execCommand(`command -v ${cmd}`);
    return success;
}

async function main() {
    if (!(await checkInstalled('argocd'))) {
        logger.error('ArgoCD CLI is not installed. Please install it first.');
        process.exit(1);
    }
    if (!(await checkInstalled('kubectl'))) {
        logger.error('kubectl is not installed. Please install it first.');
        process.exit(1);
    }

    // Check if ArgoCD is installed in cluster
    const { success } = await execCommand('kubectl get namespace argocd');
    let argocdInstalled = false;
    if (success) {
        const pods = await execCommand('kubectl get pods -n argocd');
        argocdInstalled = pods.stdout.includes('argocd-server');
    }

    if (!argocdInstalled) {
        const choice = (await question('ArgoCD is not installed. Install it? (y/n): ')).trim().toLowerCase();
        if (choice === 'y') {
            logger.info('Installing ArgoCD...');
            await execCommand('kubectl create namespace argocd');
            await execCommand('kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml');
            logger.info('Waiting for ArgoCD server...');
            await execCommand('kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd');
        } else {
            logger.error('Exiting as ArgoCD is required.');
            process.exit(1);
        }
    }

    logger.info('Retrieving ArgoCD admin password...');
    const pwResult = await execCommand('kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d');
    const password = pwResult.stdout.trim();

    logger.info('Port-forwarding ArgoCD server to localhost:8080...');
    const pfProc = Bun.spawn(['kubectl', 'port-forward', 'svc/argocd-server', '-n', 'argocd', '8080:443']);
    await new Promise((r) => setTimeout(r, 5000));

    logger.info('Logging in to ArgoCD...');
    const loginResult = await execCommand(`argocd login localhost:8080 --username admin --password ${password} --insecure`);
    if (!loginResult.success) {
        logger.error('Failed to login to ArgoCD.');
        pfProc.kill();
        process.exit(1);
    }

    logger.info('Creating ArgoCD API key...');
    const apiKeyResult = await execCommand('argocd account generate-token --account admin');
    if (apiKeyResult.success) {
        console.log('API Key:', apiKeyResult.stdout.trim());
        console.log('Save this key securely for CI/CD integration.');
    } else {
        logger.error('Failed to create API key.');
    }

    pfProc.kill();
    logger.success('ArgoCD setup complete.');
}

main();