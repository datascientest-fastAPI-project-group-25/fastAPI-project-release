%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffd8d8', 'edgeLabelBackground':'#ffffff'}}}%%
graph TD
    subgraph AWS["AWS eu-central-1 (GDPR Compliant)"]
        subgraph VPC["VPC (10.0.0.0/16)"]
            subgraph PublicSubnets["Public Subnets"]
                CF[("CloudFront<br>(CDN)"]
                ALB[("Application<br>Load Balancer")]
            end
            
            subgraph PrivateSubnets["Private Subnets"]
                subgraph EKS["EKS Cluster"]
                    ArgoCD[["Argo CD"]]
                    Backend1[["Backend Pod"]]
                    Backend2[["Backend Pod"]]
                    LBController[["ALB<br>Controller"]]
                end
                
                RDS[("RDS PostgreSQL<br>(Multi-AZ)")]
            end
            
            S3[("S3 Bucket<br>(Frontend Assets)")]
        end
    end
    
    subgraph GitHub["GitHub Ecosystem"]
        GHCR[("GHCR<br>(Container Registry)")]
        Actions[("GitHub Actions")]
    end
    
    Users[("End Users")] -->|HTTPS| CF
    CF -->|Static Content| S3
    CF -->|API Requests| ALB
    ALB --> Backend1
    ALB --> Backend2
    
    Backend1 --> RDS
    Backend2 --> RDS
    
    Actions -->|Build/Push| GHCR
    GHCR -->|Pull Images| EKS
    
    ArgoCD -.->|Manages| Backend1
    ArgoCD -.->|Manages| Backend2
    LBController -.->|Configures| ALB
    
    classDef aws fill:#FF9900,color:#000
    classDef github fill:#181717,color:#fff
    classDef users fill:#0071bc,color:#fff
    class AWS aws
    class GitHub github
    class Users users