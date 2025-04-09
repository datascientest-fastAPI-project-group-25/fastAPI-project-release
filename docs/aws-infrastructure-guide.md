# AWS Infrastructure Setup Guide for FastAPI Project

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Infrastructure Components](#infrastructure-components)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Security Considerations](#security-considerations)
5. [Monitoring Setup](#monitoring-setup)
6. [Maintenance Procedures](#maintenance-procedures)
7. [Troubleshooting Guide](#troubleshooting-guide)

## Prerequisites
- AWS Account with admin permissions
- Terraform v1.5+ installed
- kubectl configured
- GitHub repository with Argo CD configured
- GitHub PAT with `read:packages` scope
- Domain name for production environment

## Infrastructure Components

### Core Architecture
![AWS Architecture Diagram](./aws-architecture-diagram.mmd)

For an interactive version, view the [Mermaid diagram file](./aws-architecture-diagram.mmd) which can be rendered in any Mermaid-compatible viewer.

## Step-by-Step Deployment

### 1. Terraform Infrastructure Setup
```bash
# Initialize Terraform
terraform init

# Create infrastructure (GDPR-compliant EU region)
terraform apply -var="environment=production" -var="region=eu-central-1"
```

### 2. Configure EKS Cluster Access
```bash
aws eks --region eu-central-1 update-kubeconfig --name fastapi-cluster
```

### 3. Install Argo CD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 4. Configure GHCR Access
```bash
# Create secret for image pulls
kubectl create secret docker-registry ghcr-secret \
  --namespace=fastapi-production \
  --docker-server=ghcr.io \
  --docker-username=your-github-username \
  --docker-password=ghp_yourPATtoken
```

### 5. Deploy Backend via Argo CD
```yaml
# backend-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fastapi-backend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/datascientest-fastAPI-project-group-25/fastAPI-project-release
    targetRevision: fix-for-argocdChart
    path: charts/backend
  destination:
    server: https://kubernetes.default.svc
    namespace: fastapi-production
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
```

### 6. Frontend Deployment
1. Configure GitHub Actions secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `S3_BUCKET_NAME`
   - `CLOUDFRONT_DISTRIBUTION_ID`

2. Trigger frontend deployment by pushing to main branch

## Security Considerations

### IAM Policies
```hcl
# github-actions-policy.tf
data "aws_iam_policy_document" "github_actions" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.frontend.arn,
      "${aws_s3_bucket.frontend.arn}/*"
    ]
  }

  statement {
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [aws_cloudfront_distribution.frontend.arn]
  }
}
```

## Monitoring Setup

### CloudWatch Alarms
```hcl
resource "aws_cloudwatch_metric_alarm" "high_5xx_errors" {
  alarm_name          = "High5xxErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High 5xx errors from ALB"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

## Maintenance Procedures

### Database Backups
```hcl
resource "aws_db_instance" "postgres" {
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Sun:04:00-Sun:05:00"
}
```

## Troubleshooting Guide

| Issue | Solution |
|-------|----------|
| Image pull errors | Verify GHCR secret exists in namespace |
| 502 Bad Gateway | Check EKS pod logs and ALB target group health |
| Slow frontend loading | Invalidate CloudFront cache |