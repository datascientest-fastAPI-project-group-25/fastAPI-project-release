import { execCommand } from '../../utils/shell';
import { logger } from '../../utils/logger';

async function main() {
  logger.info('Cleaning up existing resources in fastapi-dev namespace...');
  await execCommand('kubectl delete -n fastapi-dev deployment,service,configmap,secret,statefulset,ingress,pvc --all --ignore-not-found');

  logger.info('Creating namespace if it does not exist...');
  await execCommand('kubectl create namespace fastapi-dev --dry-run=client -o yaml | kubectl apply -f -');

  logger.info('Installing Helm chart for DEVELOPMENT environment...');
  await execCommand('helm upgrade --install fastapi-dev ./charts/fastapi -f ./config/helm/staging.yaml --namespace fastapi-dev --create-namespace --timeout 5m --force --debug');

  logger.success('Deployment to DEVELOPMENT environment complete!');
  console.log('Run these commands to access the application:');
  console.log('kubectl port-forward -n fastapi-dev service/backend-service 8000:8000 --address 0.0.0.0');
  console.log('kubectl port-forward -n fastapi-dev service/frontend-service 5173:80 --address 0.0.0.0');
}

main();