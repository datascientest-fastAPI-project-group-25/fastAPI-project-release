import { execCommand } from '../../utils/shell';
import { logger } from '../../utils/logger';

async function main() {
  logger.info('Cleaning up existing resources in fastapi-prod namespace...');
  await execCommand('kubectl delete -n fastapi-prod deployment,service,configmap,secret,statefulset,ingress,pvc --all --ignore-not-found');

  logger.info('Creating namespace if it does not exist...');
  await execCommand('kubectl create namespace fastapi-prod --dry-run=client -o yaml | kubectl apply -f -');

  logger.info('Installing Helm chart for PRODUCTION environment...');
  await execCommand('helm upgrade --install fastapi-prod ./charts/fastapi -f ./config/helm/production.yaml --namespace fastapi-prod --create-namespace --timeout 5m --force --debug');

  logger.success('Deployment to PRODUCTION environment complete!');
  console.log('Run these commands to access the application:');
  console.log('kubectl port-forward -n fastapi-prod service/backend-service 8000:8000 --address 0.0.0.0');
  console.log('kubectl port-forward -n fastapi-prod service/frontend-service 80:80 --address 0.0.0.0');
}

main();