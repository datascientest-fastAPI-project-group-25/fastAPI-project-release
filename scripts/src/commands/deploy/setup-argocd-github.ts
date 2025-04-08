import { execCommand } from '../../utils/shell';
import { logger } from '../../utils/logger';
import { question } from '../../utils/prompt';

async function checkInstalled(cmd: string) {
    const { success } = await execCommand(`command -v ${cmd}`);
    if (!success) {
        logger.error(`${cmd} is not installed.`);
        process.exit(1);
    }
}

async function main() {
    const skipK8s = Bun.argv.includes('--skip-k8s-check');

    await checkInstalled('gh');
    if (!skipK8s) {
        await checkInstalled('kubectl');
        await checkInstalled('argocd');
    }

    // Check GitHub login
    const ghStatus = await execCommand('gh auth status');
    if (!ghStatus.success) {
        logger.error('You are not logged in to GitHub CLI.');
        process.exit(1);
    }

    let apiKey = '';

    if (!skipK8s) {
        // Check k8s connection
        const k8sConn = await execCommand('kubectl cluster-info');
        if (!k8sConn.success) {
            logger.error('Cannot connect to Kubernetes cluster.');
            process.exit(1);
        }

        // Check if ArgoCD installed
        const nsCheck = await execCommand('kubectl get namespace argocd');
        let argocdInstalled = false;
        if (nsCheck.success) {
            const pods = await execCommand('kubectl get pods -n argocd');
            argocdInstalled = pods.stdout.includes('argocd-server');
        }

        if (!argocdInstalled) {
            const choice = (await question('ArgoCD not installed. Install? (y/n): ')).trim().toLowerCase();
            if (choice === 'y') {
                await execCommand('kubectl create namespace argocd');
                await execCommand('kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml');
                await execCommand('kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd');
            } else {
                logger.error('ArgoCD required. Exiting.');
                process.exit(1);
            }
        }

        // Get admin password
        const pwResult = await execCommand('kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d');
        const password = pwResult.stdout.trim();

        // Port-forward
        const pfProc = Bun.spawn(['kubectl', 'port-forward', 'svc/argocd-server', '-n', 'argocd', '8080:443']);
        await new Promise((r) => setTimeout(r, 5000));

        // Login
        const loginResult = await execCommand(`argocd login localhost:8080 --username admin --password ${password} --insecure`);
        if (!loginResult.success) {
            logger.error('Failed to login to ArgoCD.');
            pfProc.kill();
            process.exit(1);
        }

        // Generate API key
        const apiKeyResult = await execCommand('argocd account generate-token --account admin');
        apiKey = apiKeyResult.stdout.trim();

        pfProc.kill();
    } else {
        apiKey = (await question('Enter your ArgoCD API token: ')).trim();
        if (!apiKey) {
            logger.error('API key cannot be empty.');
            process.exit(1);
        }
    }

    // Store API key as GitHub secret
    const repoResult = await execCommand('gh repo view --json nameWithOwner -q .nameWithOwner');
    const repo = repoResult.stdout.trim();
    await execCommand(`echo "${apiKey}" | gh secret set ARGOCD_AUTH_TOKEN -R "${repo}"`);

    // Store server URL as GitHub secret
    const serverUrl = (await question('Enter the ArgoCD server URL (e.g., https://argocd.example.com): ')).trim();
    await execCommand(`echo "${serverUrl}" | gh secret set ARGOCD_SERVER -R "${repo}"`);

    logger.success('ArgoCD API key and server URL stored as GitHub secrets.');
}

main();