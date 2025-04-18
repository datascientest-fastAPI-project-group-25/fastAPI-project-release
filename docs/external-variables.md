# External Variable Requirements for ArgoCD Deployments

This document outlines the external variables required for deploying the `fastapi-app` using ArgoCD, particularly focusing on the differences between staging and production environments.

## Overview

The production deployment relies on external variables injected during the Helm rendering process managed by ArgoCD. These variables allow for environment-specific configuration without hardcoding sensitive or environment-dependent values directly into the version-controlled Helm values files.

The staging environment currently uses hardcoded values defined in `config/helm/values-stg.yaml` and does not require the external variables listed below.

## Production Environment Variables

The following variables **must** be provided externally for the **production** deployment (`argocd/application-prod.yaml` which uses `config/helm/values-prod.yaml`):

1.  **`DOMAIN`**
    *   **Purpose:** Specifies the base domain name for the production environment.
    *   **Usage in `values-prod.yaml`:**
        *   `ingress.hostTemplate: "dashboard.${DOMAIN}"`
        *   `configMap.allowedOrigins: "https://dashboard.${DOMAIN}"`
    *   **Expected Format:** A valid domain name string (e.g., `mycompany.com`).
    *   **Source/Injection:** Provide via ArgoCD Application `spec.source.helm.parameters` or potentially as an environment variable accessible to the ArgoCD Application Controller if configured to pass them.

2.  **`DATABASE_URL`**
    *   **Purpose:** Provides the complete connection string for the application to connect to its production database.
    *   **Usage in `values-prod.yaml`:**
        *   `configMap.databaseUrl: "${DATABASE_URL}"`
    *   **Expected Format:** Standard database connection URL (e.g., `postgresql://user:password@host:port/dbname`).
    *   **Source/Injection:** This variable needs to be constructed and injected. The `values-prod.yaml` configures the External Secrets Operator (ESO) to fetch database credentials (`username`, `password`, `database` name) from the AWS Secrets Manager path `prod/postgres/credentials`. The final URL needs to be assembled using these credentials plus the correct database host (likely the Kubernetes service name, e.g., `postgres.fastapi-helm-prod.svc.cluster.local`) and port (`5432`). Inject the fully constructed URL via ArgoCD Application `spec.source.helm.parameters`.

3.  **`AWS_REGION`**
    *   **Purpose:** Specifies the AWS region for the External Secrets Operator (ESO) to fetch secrets from AWS Secrets Manager.
    *   **Usage in `values-prod.yaml`:**
        *   `externalSecrets.secretStores[0].region: ${AWS_REGION}`
    *   **Expected Format:** An AWS region code (e.g., `us-east-1`, `eu-central-1`).
    *   **Source/Injection:** Provide via ArgoCD Application `spec.source.helm.parameters` or potentially as an environment variable accessible to the ArgoCD Application Controller.

## External Secrets Operator (ESO) Dependency (Production)

The production deployment relies heavily on the [External Secrets Operator](https://external-secrets.io/) being installed and configured in the cluster. ESO must have the necessary permissions to access AWS Secrets Manager in the specified `AWS_REGION`.

ESO is configured in `values-prod.yaml` to fetch data for the following Kubernetes Secrets:

*   **`postgres-credentials`**: Fetches `username`, `password`, `database` from AWS secret path `prod/postgres/credentials`. These values are primarily used to construct the `DATABASE_URL`.
*   **`app-secrets`**: Fetches `secretKey` from AWS secret path `prod/app/secrets`. This is referenced by `configMap.secretKeyRef`.

Ensure the corresponding secrets exist in AWS Secrets Manager in the target region before deploying to production.

## Providing Variables via ArgoCD

The recommended way to provide these variables is through the `helm.parameters` section in the ArgoCD `Application` manifest (`argocd/application-prod.yaml`).

Example snippet for `application-prod.yaml`:

```yaml
spec:
  source:
    repoURL: ...
    targetRevision: HEAD
    path: charts/fastapi
    helm:
      valueFiles:
        - ../../config/helm/values-prod.yaml
      parameters:
        - name: configMap.databaseUrl # Example for DATABASE_URL
          value: "postgresql://<user>:<password>@<host>:<port>/<db>"
        - name: ingress.hostTemplate # Example for DOMAIN usage
          value: "dashboard.yourdomain.com"
        - name: configMap.allowedOrigins # Example for DOMAIN usage
          value: "https://dashboard.yourdomain.com"
        - name: externalSecrets.secretStores[0].region # Example for AWS_REGION
          value: "eu-central-1"
```

**Note:** The `DOMAIN` variable is used in multiple places (`ingress.hostTemplate`, `configMap.allowedOrigins`). You need to provide parameters that override the specific Helm values where `${DOMAIN}` is used, rather than providing `DOMAIN` itself as a parameter, unless the Helm templates are explicitly written to substitute `${DOMAIN}` from a single top-level parameter. Based on `values-prod.yaml`, direct overrides like the example above are necessary.

## Verification

After deployment via ArgoCD:

1.  **Check ConfigMap:** Verify the `databaseUrl` and `allowedOrigins` have the correct, interpolated values.
    ```bash
    kubectl get configmap fastapi-app-config -n fastapi-helm-prod -o yaml
    ```
2.  **Check Ingress:** Ensure the `host` is set correctly.
    ```bash
    kubectl get ingress fastapi-app-ingress -n fastapi-helm-prod -o yaml
    ```
3.  **Check ExternalSecrets:** Verify that the `ExternalSecret` resources were created and their status is `SecretSynced`.
    ```bash
    kubectl get externalsecrets -n fastapi-helm-prod
    kubectl describe externalsecret postgres-credentials -n fastapi-helm-prod
    kubectl describe externalsecret app-secrets -n fastapi-helm-prod
    ```
4.  **Check Secrets:** Confirm that the corresponding Kubernetes `Secret` resources (`postgres-credentials`, `app-secrets`) were created by ESO.
    ```bash
    kubectl get secret postgres-credentials -n fastapi-helm-prod
    kubectl get secret app-secrets -n fastapi-helm-prod
    ```
5.  **Check Application Logs:** Inspect backend application logs for any errors related to database connection or configuration loading.

## Troubleshooting

*   **ArgoCD Sync Errors:** Check the ArgoCD UI for sync errors, often related to Helm rendering failures if parameters are missing or malformed.
*   **Incorrect Values in Resources:** Double-check the `helm.parameters` in the ArgoCD Application manifest for typos or incorrect values.
*   **ESO Errors (`SecretSynced` False):**
    *   Verify ESO pods are running (`kubectl get pods -n external-secrets`).
    *   Check ESO pod logs for errors related to AWS authentication or secret fetching.
    *   Ensure the specified `AWS_REGION` is correct.
    *   Confirm the secrets exist in AWS Secrets Manager at the specified paths (`prod/postgres/credentials`, `prod/app/secrets`).
    *   Verify ESO has the correct IAM permissions in AWS.
*   **Application Errors:** If the application fails to start or function correctly, check its logs for specific errors related to database connection (`DATABASE_URL`), CORS (`allowedOrigins`), or missing secrets (`secretKey`).