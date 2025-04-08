import { $ } from 'bun'; // Assuming 'bun' types are correctly configured globally or via tsconfig
import { logger } from '../../utils/logger';
import { execCommand } from '../../utils/shell';
import { isCI } from '../../utils/ci'; // Assuming a utility function exists or will be created
import fs from 'fs/promises';
import path from 'path';
import os from 'os';

const TEMP_PORT_FILE = path.join(os.tmpdir(), 'argocd-cluster-port.txt');

// Helper function to check if a command exists
async function commandExists(command: string): Promise<boolean> {
    try {
        // Use 'which' for Unix-like systems, 'where' for Windows
        const checkCmd = process.platform === 'win32' ? 'where' : 'which';
        // Use Bun's $ for simpler command execution and error handling
        await $`${checkCmd} ${command}`.quiet();
        return true;
    } catch (error) {
        // Bun's $ throws an error if the command fails or is not found
        return false;
    }
}

// Function to install tools in CI
async function installToolsInCI() {
    if (isCI()) {
        logger.info("CI environment detected, installing required tools automatically...");

        // Install k3d
        logger.info("Installing k3d...");
        try {
            await $`curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash`.quiet();
            logger.success("k3d installed.");
        } catch (e: any) {
            logger.warn(`Failed to install k3d automatically: ${e.message}`);
        }

        // Install kubectl (Linux assumed in CI for this example)
        logger.info("Installing kubectl...");
        try {
            await $`curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"`.quiet();
            await $`chmod +x kubectl`.quiet();
            // Note: sudo might require password, could fail in some CI. Consider alternatives if needed.
            await $`sudo mv kubectl /usr/local/bin/`.quiet();
            logger.success("kubectl installed.");
        } catch (e: any) {
            logger.warn(`Failed to install kubectl automatically: ${e.message}`);
        }

        // Install Helm
        logger.info("Installing Helm...");
        try {
            await $`curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`.quiet();
            logger.success("Helm installed.");
        } catch (e: any) {
            logger.warn(`Failed to install Helm automatically: ${e.message}`);
        }

        logger.info("Attempted automatic tool installation.");
    }
}

// Function to check required tools
async function checkTools() {
    logger.info("Checking required tools...");

    // Try installing in CI first
    await installToolsInCI();

    const tools = [
        { name: 'k3d', install: 'macOS: brew install k3d | Linux: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash | Win: choco install k3d | https://k3d.io/#installation' },
        { name: 'kubectl', install: 'macOS: brew install kubectl | Linux: see https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/ | https://kubernetes.io/docs/tasks/tools/install-kubectl/' },
        { name: 'helm', install: 'macOS: brew install helm | Linux: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash | https://helm.sh/docs/intro/install/' },
    ];

    let allToolsFound = true;
    for (const tool of tools) {
        if (!(await commandExists(tool.name))) {
            logger.error(`❌ ${tool.name} is not installed. Please install it first.`);
            logger.info(`   Installation instructions: ${tool.install}`);
            allToolsFound = false;
        }
    }

    if (!allToolsFound) {
        throw new Error("Required tools are missing.");
    }

    logger.success("✅ All required tools are installed.");
}


// Main command logic
export async function setupLocalK3dArgoCD() {
    logger.info('=== Setting up local k3d cluster with ArgoCD ===');
    console.log(); // Replaced logger.line()

    // 1. Check tools
    await checkTools();
    console.log();

    // 2. Create cluster
    await createCluster();
    console.log();

    // 3. Install ArgoCD
    await installArgoCD();
    console.log();

    // 4. Get admin password
    const adminPassword = await getAdminPassword();
    console.log();

    // 5. Get server URL
    const serverUrl = await getServerUrl();
    console.log();

    // 6. Print final instructions
    printFinalInstructions(serverUrl, adminPassword);

    // Remove placeholder messages
}


// Function to create k3d cluster
async function createCluster() {
    const clusterName = 'argocd-cluster';
    logger.info(`Creating k3d cluster '${clusterName}'...`);

    try {
        // Check if cluster exists
        const clusterListOutput = await $`k3d cluster list`.text();
        const clusterExists = clusterListOutput.includes(clusterName);

        if (clusterExists) {
            logger.info(`Cluster '${clusterName}' already exists.`);
            // Check if the cluster is running (assuming 1 server node)
            // A more robust check might parse the output more carefully
            const clusterRunning = clusterListOutput.includes(`${clusterName}`) && /\s1\/1\s/.test(clusterListOutput);
            if (!clusterRunning) {
                logger.info(`Starting cluster '${clusterName}'...`);
                await $`k3d cluster start ${clusterName}`.quiet();
            }
        } else {
            // Create a new cluster, trying specific ports first
            logger.info("Attempting to create cluster with specific ports...");
            let clusterCreated = false;
            const portsToTry = [8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089, 8090];

            for (const port of portsToTry) {
                logger.info(`Trying port ${port}...`);
                try {
                    // Added --timeout for wait
                    await $`k3d cluster create ${clusterName} --servers 1 --agents 1 --port ${port}:80@loadbalancer --wait --timeout 300s`.quiet();
                    await fs.writeFile(TEMP_PORT_FILE, port.toString());
                    logger.success(`Cluster created with port ${port}.`);
                    clusterCreated = true;
                    break;
                } catch (createError: any) {
                    logger.warn(`Failed with port ${port}: ${createError.message?.split('\n')[0] ?? createError}. Cleaning up...`);
                    // Ensure cleanup even if creation partially failed
                    await $`k3d cluster delete ${clusterName}`.quiet().catch(() => { }); // Ignore errors during cleanup
                }
            }

            // If specific ports failed, try a random port
            if (!clusterCreated) {
                logger.info("Specific ports failed, trying with a random port...");
                try {
                    await $`k3d cluster create ${clusterName} --servers 1 --agents 1 --port 0:80@loadbalancer --wait --timeout 300s`.quiet();
                    // Getting the random port reliably is complex, might involve parsing kubectl get svc k3d-<clustername>-server-lb -o jsonpath='{.spec.ports[0].nodePort}'
                    // For simplicity, we'll warn the user.
                    logger.warn("Cluster created with random port. Port forwarding might be needed manually or check 'k3d cluster list'.");
                    // Clear any old port file if it exists
                    await fs.unlink(TEMP_PORT_FILE).catch(() => { }); // Ignore error if file doesn't exist
                    clusterCreated = true;
                } catch (randomError: any) {
                    logger.error(`❌ Failed to create cluster with any port: ${randomError.message}`);
                    logger.error("Please check your Docker and network configuration.");
                    throw new Error("k3d cluster creation failed.");
                }
            }


            // Function to install ArgoCD using Helm
            async function installArgoCDHelm() {
                logger.info("Installing ArgoCD using Helm...");
                const namespace = 'argocd';

                try {
                    logger.info("Adding ArgoCD Helm repository...");
                    await $`helm repo add argo https://argoproj.github.io/argo-helm`.quiet();
                    await $`helm repo update`.quiet();

                    logger.info(`Creating namespace '${namespace}' if it doesn't exist...`);
                    // Use --dry-run=client and apply to be idempotent
                    const createNsManifest = await $`kubectl create namespace ${namespace} --dry-run=client -o yaml`.text();
                    await $`kubectl apply -f -`.stdin(createNsManifest).quiet();


                    logger.info("Installing/upgrading ArgoCD Helm chart...");
                    await $`helm upgrade --install argocd argo/argo-cd \
                    --namespace ${namespace} \
                    --set server.service.type=LoadBalancer \
                    --wait --timeout 5m`.quiet(); // Added timeout

                    logger.success("✅ ArgoCD installed via Helm successfully.");
                } catch (error: any) {
                    logger.error(`❌ Failed to install ArgoCD using Helm: ${error.message}`);
                    throw error;
                }
            }

            // Function to install ArgoCD using kubectl
            async function installArgoCDKubectl() {
                logger.info("Installing ArgoCD using kubectl...");
                const namespace = 'argocd';

                try {
                    logger.info(`Creating namespace '${namespace}' if it doesn't exist...`);
                    const createNsManifest = await $`kubectl create namespace ${namespace} --dry-run=client -o yaml`.text();
                    await $`kubectl apply -f -`.stdin(createNsManifest).quiet();

                    logger.info("Applying ArgoCD manifests...");
                    await $`kubectl apply -n ${namespace} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`.quiet();

                    logger.info("Patching argocd-server service to LoadBalancer...");
                    await $`kubectl patch svc argocd-server -n ${namespace} -p '{"spec": {"type": "LoadBalancer"}}'`.quiet();

                    logger.info("Waiting for ArgoCD server deployment to be available...");
                    await $`kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n ${namespace}`.quiet();

                    logger.success("✅ ArgoCD installed via kubectl successfully.");
                } catch (error: any) {
                    logger.error(`❌ Failed to install ArgoCD using kubectl: ${error.message}`);
                    throw error;
                }
            }

            // Function to determine and execute ArgoCD installation
            async function installArgoCD() {
                // Use environment variable ARGOCD_INSTALL_METHOD if set, otherwise default to kubectl
                const installMethod = process.env.ARGOCD_INSTALL_METHOD?.toLowerCase() || 'kubectl';
                logger.info(`Selected ArgoCD installation method: ${installMethod}`);

                if (installMethod === 'helm') {
                    await installArgoCDHelm();
                } else {
                    if (installMethod !== 'kubectl') {
                        logger.warn(`Unknown ARGOCD_INSTALL_METHOD '${process.env.ARGOCD_INSTALL_METHOD}', defaulting to 'kubectl'.`);
                    }
                    await installArgoCDKubectl();
                }
            }


            // Function to get ArgoCD admin password
            async function getAdminPassword(): Promise<string> {
                logger.info("Retrieving ArgoCD admin password...");
                const namespace = 'argocd';
                const secretName = 'argocd-initial-admin-secret';

                try {
                    logger.info(`Waiting for secret '${secretName}' to exist...`);
                    // Wait for the secret object itself
                    await $`kubectl wait --for=condition=exists -n ${namespace} secret/${secretName} --timeout=120s`.quiet();
                    // Additionally, wait for the data field to be populated (can take a moment after creation)
                    await $`kubectl wait --for=jsonpath='{.data.password}' -n ${namespace} secret/${secretName} --timeout=60s`.quiet();


                    logger.info("Secret found, retrieving password...");
                    const passwordBase64 = await $`kubectl -n ${namespace} get secret ${secretName} -o jsonpath="{.data.password}"`.text();

                    if (!passwordBase64) {
                        throw new Error("Password field not found in secret.");
                    }

                    const password = Buffer.from(passwordBase64, 'base64').toString('utf-8');

                    if (!password) {
                        throw new Error("Failed to decode password.");
                    }

                    // Don't log the actual password here for security, return it instead
                    logger.success("✅ ArgoCD admin password retrieved.");
                    return password;
                } catch (error: any) {
                    logger.error(`❌ Failed to retrieve ArgoCD admin password: ${error.message}`);
                    // Try to get logs from argocd-server pod for debugging
                    try {
                        logger.info("Attempting to get logs from argocd-server pod...");
                        const logs = await $`kubectl logs -n ${namespace} deployment/argocd-server --tail=50`.text();
                        logger.info("argocd-server logs (last 50 lines):\n" + logs);
                    } catch (logError: any) {
                        logger.warn(`Could not retrieve argocd-server logs: ${logError.message}`);
                    }
                    throw new Error("Failed to get ArgoCD admin password.");
                }
            }

            // Function to get ArgoCD server URL
            async function getServerUrl(): Promise<string> {
                logger.info("Getting ArgoCD server URL...");
                const namespace = 'argocd';
                const serviceName = 'argocd-server';
                let clusterPort = '8081'; // Default

                try {
                    // Try reading the port saved during cluster creation
                    clusterPort = await fs.readFile(TEMP_PORT_FILE, 'utf-8').catch(() => {
                        logger.warn(`Could not read ${TEMP_PORT_FILE}, assuming default port 8081 for k3d host access.`);
                        return '8081'; // Return default if file read fails
                    });
                    clusterPort = clusterPort.trim(); // Ensure no extra whitespace

                    logger.info(`Waiting for ${serviceName} service to get an external IP or be ready...`);
                    // Wait for LoadBalancer Ingress IP
                    await $`kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' --timeout=300s service/${serviceName} -n ${namespace}`.quiet();

                    const serverIp = await $`kubectl get svc ${serviceName} -n ${namespace} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`.text();
                    const serverPort = await $`kubectl get svc ${serviceName} -n ${namespace} -o jsonpath='{.spec.ports[?(@.name=="https")].port}'`.text(); // Get HTTPS port

                    let serverUrl = '';
                    if (serverIp && serverPort) {
                        serverUrl = `${serverIp}:${serverPort}`;
                        logger.success(`✅ ArgoCD server IP found: ${serverIp}:${serverPort}`);
                    } else {
                        // Fallback if IP isn't assigned (e.g., some k3d setups or network policies)
                        logger.warn("Could not get external IP for ArgoCD server.");
                        serverUrl = `localhost:${clusterPort}`; // Use the k3d mapped host port
                        logger.info(`Assuming access via k3d port-forwarding: https://${serverUrl}`);
                    }
                    logger.success(`✅ ArgoCD server URL determined: https://${serverUrl}`);
                    return serverUrl; // Return only host:port, protocol added in final message

                } catch (error: any) {
                    logger.warn(`⚠️ Failed to get ArgoCD server external IP: ${error.message}`);
                    logger.info(`Falling back to k3d host port mapping: https://localhost:${clusterPort}`);
                    // Fallback to using the k3d mapped port
                    return `localhost:${clusterPort}`;
                }
            }

            // Function to print final instructions
            function printFinalInstructions(serverUrl: string, adminPassword: string) {
                console.log();
                logger.success("=== Setup Complete ===");
                console.log();
                logger.info("ArgoCD is now running in your local k3d cluster.");
                console.log();
                logger.info("To access the ArgoCD UI:");
                logger.info(`  URL: https://${serverUrl}`);
                logger.info("  Username: admin");
                logger.info(`  Password: ${adminPassword}`);
                console.log();
                logger.info("To login using the ArgoCD CLI:");
                logger.info(`  argocd login ${serverUrl} --username admin --password '${adminPassword}' --insecure`); // Added quotes for password
                console.log();
                logger.info("To generate an API key for CI/CD integration:");
                logger.info("  argocd account generate-token --account admin");
                console.log();
                logger.info("To set up GitHub secrets for ArgoCD integration (if needed):");
                logger.info("  bun run setup:argocd-github"); // Assuming bun script exists
                console.log();
            }
        }

        // Set kubectl context
        logger.info(`Setting kubectl context to '${clusterName}'...`);
        await $`k3d kubeconfig merge ${clusterName} --kubeconfig-switch-context`.quiet();

        logger.success(`✅ k3d cluster '${clusterName}' is ready.`);

    } catch (error: any) {
        logger.error(`Error during cluster creation: ${error.message}`);
        throw error; // Re-throw the error to stop the script
    }
}

// If this file is executed directly (e.g., for testing)
if (import.meta.main) {
    setupLocalK3dArgoCD().catch(error => {
        logger.error(`Error setting up local k3d ArgoCD: ${error.message}`);
        process.exit(1);
    });
}