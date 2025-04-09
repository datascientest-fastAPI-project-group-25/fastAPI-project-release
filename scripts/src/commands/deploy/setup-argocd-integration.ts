import { execCommand } from '../../utils/shell';
import { logger } from '../../utils/logger';

async function main() {
    const server = process.env.ARGOCD_SERVER;
    const token = process.env.ARGOCD_AUTH_TOKEN;

    if (!server || !token) {
        logger.error('ARGOCD_SERVER and ARGOCD_AUTH_TOKEN environment variables must be set.');
        process.exit(1);
    }

    const ref = process.env.GITHUB_REF || '';
    const prNumber = ref.replace('refs/pull/', '').replace('/merge', '');
    const branch = process.env.GITHUB_HEAD_REF || '';

    if (!prNumber || !branch) {
        logger.error('Could not determine PR number or branch name.');
        process.exit(1);
    }

    logger.info(`Setting up ArgoCD integration for PR #${prNumber} from branch ${branch}`);

    await execCommand(`argocd login --insecure --server ${server} --auth-token ${token}`);

    const appName = `fastapi-pr-${prNumber}`;
    const namespace = `fastapi-pr-${prNumber}`;

    const appExists = (await execCommand(`argocd app get ${appName}`)).success;

    if (appExists) {
        logger.info(`Updating existing app ${appName}`);
        await execCommand(`argocd app set ${appName} --repo https://github.com/datascientest-fastapi-project-group-25/fastAPI-project-release.git --path charts/fastapi --revision ${branch} --helm-set "app.namespace=${namespace}" --values ../../config/helm/playground.yaml`);
    } else {
        logger.info(`Creating new app ${appName}`);
        await execCommand(`argocd app create ${appName} --repo https://github.com/datascientest-fastapi-project-group-25/fastAPI-project-release.git --path charts/fastapi --revision ${branch} --dest-server https://kubernetes.default.svc --dest-namespace ${namespace} --helm-set "app.namespace=${namespace}" --values ../../config/helm/playground.yaml --sync-policy automated --auto-prune --self-heal`);
    }

    logger.info(`Syncing app ${appName}`);
    await execCommand(`argocd app sync ${appName} --prune`);

    logger.info(`Waiting for sync to complete...`);
    await execCommand(`argocd app wait ${appName} --health --timeout 300`);

    logger.info(`Application status:`);
    await execCommand(`argocd app get ${appName}`);

    console.log(`Application URL: https://pr-${prNumber}.fastapi-project-release.com`);
    console.log('Note: This URL will only work if DNS is properly configured.');
}

main();