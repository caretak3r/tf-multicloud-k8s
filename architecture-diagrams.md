# Air-gapped EKS Architecture Diagrams

This document contains comprehensive Mermaid diagrams for the air-gapped EKS environment architecture.

## 1. High-level Architecture Overview

```mermaid
graph TB
    subgraph "External Access"
        ADMIN[Cloud Administrators]
        VPN_CLIENT[OpenVPN Client]
    end

    subgraph "AWS Environment"
        subgraph "Air-gapped VPC (172.16.0.0/16)"
            subgraph "VPN Subnet (172.16.100.0/24)"
                VPN[Client VPN Endpoint]
                VPN_SG[VPN Security Group]
            end

            subgraph "Private Subnets"
                subgraph "AZ1 - Private (172.16.1.0/24)"
                    EKS1[EKS Control Plane ENI]
                    NG1_System[System Node Group]
                    NG1_App[Application Node Group]
                    EP1[VPC Endpoints]
                end

                subgraph "AZ2 - Private (172.16.2.0/24)"
                    EKS2[EKS Control Plane ENI]
                    NG2_System[System Node Group]
                    NG2_App[Application Node Group]
                    EP2[VPC Endpoints]
                end

                subgraph "AZ3 - Private (172.16.3.0/24)"
                    EKS3[EKS Control Plane ENI]
                    NG3_System[System Node Group]
                    NG3_App[Application Node Group]
                    EP3[VPC Endpoints]
                end
            end

            subgraph "VPC Endpoint Network"
                subgraph "Interface Endpoints"
                    EKS_EP[EKS API]
                    ECR_EP[ECR API/DKR]
                    EC2_EP[EC2 Service]
                    STS_EP[STS Service]
                    ELB_EP[Load Balancer]
                    CW_EP[CloudWatch Logs]
                    KMS_EP[KMS]
                    SM_EP[Secrets Manager]
                    SSM_EP[SSM]
                end

                subgraph "Gateway Endpoints"
                    S3_EP[S3]
                end
            end
        end

        subgraph "AWS Services PrivateLink"
            ECR_SERVICE[Amazon ECR]
            S3_SERVICE[Amazon S3]
            AWS_EKS[Amazon EKS]
            AUTH_SERVICE[STS/IAM]
            LB_SERVICE[Load Balancers]
            MONITORING[CloudWatch]
            KEY_SERVICE[KMS]
            SECRET_SERVICE[Secrets Manager]
            CONFIG_SERVICE[Systems Manager]
        end
    end

    %% Connections
    ADMIN -->|Setup VPN Connection| VPN_CLIENT
    VPN_CLIENT -->|OpenVPN Tunnel| VPN
    VPN -.->|DNS Resolution| VPN_SG
    VPN -.->|Authorized Access| EKS1
    VPN -.->|Authorized Access| NG1_System
    VPN -.->|Authorized Access| NG1_App

    %% EKS to AWS Services via VPC Endpoints
    EKS1 -->|Private Connection| EKS_EP
    EKS_EP -->|PrivateLink| AWS_EKS

    NG1_System -->|Image Pull| ECR_EP
    ECR_EP -->|PrivateLink| ECR_SERVICE

    EKS1 -->|Blob Storage| S3_EP
    S3_EP -->|PrivateLink| S3_SERVICE

    EKS1 -->|Instance Management| EC2_EP
    EC2_EP -->|PrivateLink| AUTH_SERVICE

    EKS1 -->|Load Balancer Management| ELB_EP
    ELB_EP -->|PrivateLink| LB_SERVICE

    EKS1 -->|Log Forwarding| CW_EP
    CW_EP -->|PrivateLink| MONITORING

    EKS1 -->|Secret Access| SM_EP
    SM_EP -->|PrivateLink| SECRET_SERVICE

    %% VPN CloudWatch Access
    VPN -->|Log Transfer| CW_EP

    %% System Components to App Components
    NG1_System -->|API Calls| NG1_App
    NG1_System -->|Service Discovery| NG2_App
    NG1_System -->|Load Balancing| NG3_App
```

## 2. VPC Endpoint Architecture

```mermaid
flowchart TD
    subgraph "VPC Endpoint Architecture"
        subgraph "Security Groups"
            CLUSTER_SG[Cluster SG]
            NODES_SG[Nodes SG]
            ENDPOINT_SG[Endpoint SG]
            VPN_SG[VPN SG]
        end

        subgraph "Interface Endpoints - Required"
            EKS_EP[EKS API<br/>com.amazonaws.region.eks]
            ECR_API[ECR API<br/>com.amazonaws.region.ecr.api]
            ECR_DKR[ECR Docker<br/>com.amazonaws.region.ecr.dkr]
            EC2_EP[EC2 API<br/>com.amazonaws.region.ec2]
            STS_EP[STS<br/>com.amazonaws.region.sts]
            ELB_EP[ELB/ALB<br/>com.amazonaws.region.elasticloadbalancing]
        end

        subgraph "Interface Endpoints - Recommended"
            LOGS_EP[CloudWatch Logs<br/>com.amazonaws.region.logs]
            KMS_EP[KMS<br/>com.amazonaws.region.kms]
            SM_EP[SecretsManager<br/>com.amazonaws.region.secretsmanager]
            SSM_EP[SSM<br/>com.amazonaws.region.ssm]
            SSM_MSG[SSM Messages<br/>com.amazonaws.region.ssmmessages]
            EC2_MSG[EC2 Messages<br/>com.amazonaws.region.ec2messages]
        end

        subgraph "Gateway Endpoints"
            S3_EP[S3<br/>com.amazonaws.region.s3]
            DDB_EP[DynamoDB<br/>com.amazonaws.region.dynamodb<br/>Optional]
        end
    end

    %% Security Group Connections
    ENDPOINT_SG -->|Allow from| CLUSTER_SG
    ENDPOINT_SG -->|Allow from| NODES_SG
    ENDPOINT_SG -->|Allow from| VPN_SG

    %% Endpoint Security Groups
    EKS_EP -.->ENDPOINT_SG
    ECR_API -.->ENDPOINT_SG
    ECR_DKR -.->ENDPOINT_SG
    EC2_EP -.->ENDPOINT_SG
    STS_EP -.->ENDPOINT_SG
    ELB_EP -.->ENDPOINT_SG

    LOGS_EP -.->ENDPOINT_SG
    KMS_EP -.->ENDPOINT_SG
    SM_EP -.->ENDPOINT_SG
    SSM_EP -.->ENDPOINT_SG
    SSM_MSG -.->ENDPOINT_SG
    EC2_MSG -.->ENDPOINT_SG

    %% Gateway Endpoints don't need SGs
    S3_EP -.->|Route Table Integration| CLUSTER_SG
    DDB_EP -.->|Route Table Integration| CLUSTER_SG
```

## 3. Security Group Traffic Flow

```mermaid
sequenceDiagram
    participant Admin as VPN Admin
    participant VPN as VPN Endpoint
    participant VPC_EP as VPC Endpoints
    participant EKS as EKS Control Plane
    participant Nodes as Worker Nodes
    participant AWS_Svc as AWS Services

    Admin->>VPN: Initiate VPN Connection
    VPN->>EKS: HTTPS to EKS API (Private)
    EKS->>VPC_EP: Service API Calls

    VPC_EP->>AWS_Svc: PrivateLink Connection

    Note over Nodes: Node Bootstrap Process
    Nodes->>VPC_EP: Docker Registry Access
    VPC_EP->>AWS_Svc: ECR Image Pull

    Nodes->>VPC_EP: Instance Metadata
    VPC_EP->>AWS_Svc: EC2 API Call

    Nodes->>VPC_EP: Kubernetes Token
    VPC_EP->>AWS_Svc: STS Token Exchange

    Note over Nodes: Application Runtime
    Nodes->>VPC_EP: Application Logs
    VPC_EP->>AWS_Svc: CloudWatch Logs

    Nodes->>VPC_EP: Config Management
    VPC_EP->>AWS_Svc: SSM Parameter Store

    Nodes->>VPC_EP: Load Balancer Management
    VPC_EP->>AWS_Svc: ELB API
```

## 4. Helm Chart Deployment Flow

```mermaid
flowchart TD
    subgraph "Helm Deployment Process"
        subgraph "Chart Sources"
            PRIVATE_ECR[Private ECR Repository]
            CHART_ARTIFACT[Helm Chart Archive(.tgz)]
            VALUES_TMPL[Values Template Files]
        end

        subgraph "Deployment Pipeline"
            INIT[Initialize Helm]
            ADD_REPO[Add Private ECR Repo]
            DEPLOY_UMBRELLA[Deploy Umbrella Chart]

            subgraph "System Component Deployment"
                INGRESS[Deploy Ingress Controller]
                MONITORING[Deploy Monitoring Stack]
                SECURITY[Deploy Security Tools]
                STORAGE[Deploy Storage Drivers]
            end

            subgraph "Application Deployment"
                APP_CHARTS[Deploy Application Charts]
                APP_CONFIG[Apply App Configurations]
                APP_ROLLOUT[Rollout Updates]
            end
        end

        subgraph "Node Group Assignment"
            SYSTEM_NG[System Node Group<br/>Scope: System<br/>Taint: CriticalAddonsOnly]
            APP_NG[Application Node Group<br/>Scope: Application<br/>No Taints]
        end

        subgraph "Post-Deployment"
            VALIDATE[Validate Deployment]
                HEALTH_CHECK[Health Check Deployment]
                CONNECTIVITY[Verify Connectivity]
        end
    end

    %% Flow Connections
    PRIVATE_ECR --> CHART_ARTIFACT
    VALUES_TMPL --> INIT

    INIT --> ADD_REPO
    ADD_REPO --> DEPLOY_UMBRELLA

    DEPLOY_UMBRELLA --> INGRESS
    DEPLOY_UMBRELLA --> MONITORING
    DEPLOY_UMBRELLA --> SECURITY
    DEPLOY_UMBRELLA --> STORAGE

    DEPLOY_UMBRELLA --> APP_CHARTS
    APP_CHARTS --> APP_CONFIG
    APP_CONFIG --> APP_ROLLOUT

    %% Node Group Assignments
    INGRESS -.->|tolerates CriticalAddonsOnly| SYSTEM_NG
    MONITORING -.->|tolerates CriticalAddonsOnly| SYSTEM_NG
    SECURITY -.->|tolerates CriticalAddonsOnly| SYSTEM_NG
    STORAGE -.->|tolerates CriticalAddonsOnly| SYSTEM_NG

    APP_CHARTS -.->|no taints required| APP_NG
    APP_CONFIG -.->|no taints required| APP_NG
    APP_ROLLOUT -.->|no taints required| APP_NG

    %% Validation
    APP_ROLLOUT --> VALIDATE
    VALIDATE --> HEALTH_CHECK
    VALIDATE --> CONNECTIVITY
```

## 5. Container Image Flow for Air-gap

```mermaid
graph LR
    subgraph "External Environment"
        DOCKER_HUB[Docker Hub]
        QUAY[Quay.io]
        GHCR[GitHub Container Registry]
        PUBLIC_REG[Other Public Registries]
    end

    subgraph "Connected Environment"
        SYNC_SERVER[Image Sync Server]
        BUILD_SERVER[Build Pipeline]
        SECURITY_SCAN[Security Scanning]
    end

    subgraph "Secure Transfer"
        SECURE_CONN[Encrypted Transfer]
        FIREWALL[Firewall Rules]
        TRANSFER_CERT[X.509 Transfer Certs]
    end

    subgraph "Air-gapped Environment"
        subgraph "Private Image Store"
            PRIVATE_ECR[Private ECR]
            IMAGE_REPO[System Images]
            CHART_REPO[Helm Charts]
        end

        subgraph "Kubernetes Cluster"
            CONTROL_PLANE[EKS Control Plane]
            SYSTEM_NG[System Nodes]
            APP_NG[Application Nodes]

            subgraph "Deployed Components"
                INGRESS_CTRL[Ingress Controller]
                MONITOR_STACK[Monitoring Stack]
                APP_SERVICES[Application Services]
            end
        end
    end

    %% External to Connected
    DOCKER_HUB -->|Image Pull| SYNC_SERVER
    QUAY -->|Image Pull| SYNC_SERVER
    GHCR -->|Image Pull| SYNC_SERVER
    PUBLIC_REG -->|Image Pull| SYNC_SERVER

    SYNC_SERVER -->|Tag/Version| BUILD_SERVER
    BUILD_SERVER -->|Vulnerability Scan| SECURITY_SCAN
    SECURITY_SCAN -->|Signed Images| PRIVATE_ECR

    %% Connected to Air-gap
    PRIVATE_ECR -->|Secure Transfer| SECURE_CONN
    SECURE_CONN -->|Certificate Auth| FIREWALL
    FIREWALL -.->|Limited Access| TRANSFER_CERT
    TRANSFER_CERT -->|Image Import| PRIVATE_ECR

    %% Internal Flow
    PRIVATE_ECR -->|Image Pull| CONTROL_PLANE
    CONTROL_PLANE -->|Image Distribution| SYSTEM_NG
    CONTROL_PLANE -->|Image Distribution| APP_NG

    SYSTEM_NG -->|Deploy| INGRESS_CTRL
    SYSTEM_NG -->|Deploy| MONITOR_STACK
    APP_NG -->|Deploy| APP_SERVICES

    %% Chart Deployment
    CHART_REPO -->|Helm Install| CONTROL_PLANE
```

## 6. Network Traffic Flow Analysis

```mermaid
flowchart TD
    subgraph "Traffic Categories"
        subgraph "Management Traffic"
            ADMIN_VPN[Admin VPN Connection]
            K8S_API[Kubernetes API]
            HELM_DEPLOY[Helm Deployments]
            KUBECTL[Kubectl Commands]
        end

        subgraph "Control Plane Traffic"
            ETCD_REPLICATION[etcd Replication]
            NODE_HEARTBEAT[Node Heartbeats]
            SCHEDULER_DEC[Scheduler Decisions]
            CONTROLLER_MGR[Controller Manager]
        end

        subgraph "Application Traffic"
            POD_COMM[Pod to Pod Comm]
            SVC_DISCOVER[Service Discovery]
            INGRESS_ROUTES[Ingress Routing]
            LOAD_BALANCER[Load Balancer]
        end

        subgraph "AWS Service Traffic"
            ECR_PULL[ECR Image Pull]
            S3_ACCESS[S3 Storage]
            CW_LOGS[CloudWatch Logs]
            IAM_STS[IAM/STS Tokens]
            ELB_ACCESS[Load Balancer API]
        end
    end

    subgraph "Network Pathways"
        subgraph "VPN Path"
            VPN_SERVER[VPN Server]
            VPN_ENI[VPN ENI]
        end

        subgraph "VPC Endpoint Path"
            INTERFACE_EP[Interface Endpoints]
            GATEWAY_EP[Gateway Endpoints]
        end

        subgraph "Internal VPC Path"
            CLUSTER_SG[Cluster SG Traffic]
            NODE_SG[Node SG Traffic]
            POD_NETWORK[Pod Network]
        end
    end

    %% Management Traffic Flow
    ADMIN_VPN -->|OpenVPN| VPN_SERVER
    VPN_SERVER -->|HTTPS| VPN_ENI
    VPN_ENI -->|Private IP| K8S_API
    K8S_API -->|gRPC| HELM_DEPLOY
    HELM_DEPLOY -->|gRPC| KUBECTL

    %% Control Plane Flow
    ETCD_REPLICATION -->|TCP| CLUSTER_SG
    NODE_HEARTBEAT -->|HTTPS| CLUSTER_SG
    SCHEDULER_DEC -->|gRPC| CLUSTER_SG
    CONTROLLER_MGR -->|gRPC| CLUSTER_SG

    %% Application Traffic Flow
    POD_COMM -->|Overlay Network| POD_NETWORK
    SVC_DISCOVER -->|DNS/ClusterIP| POD_NETWORK
    INGRESS_ROUTES -->|NodePort| POD_NETWORK
    LOAD_BALANCER -->|ELB API| INTERFACE_EP

    %% AWS Service Traffic Flow
    ECR_PULL -->|HTTPS| INTERFACE_EP
    S3_ACCESS -->|HTTPS| GATEWAY_EP
    CW_LOGS -->|HTTPS| INTERFACE_EP
    IAM_STS -->|HTTPS| INTERFACE_EP
    ELB_ACCESS -->|HTTPS| INTERFACE_EP
```

## 7. Conditional Logic Flow

```mermaid
flowchart TD
    START[Terraform Apply] --> CHECK_TYPE{Check cluster_type}

    CHECK_TYPE -->|"cluster_type = 'api-product'"| STANDARD_PATH
    CHECK_TYPE -->|"cluster_type = 'airgap'"| AIRGAP_PATH

    subgraph "Standard Path (Current Behavior)"
        STANDARD_PATH --> STANDARD_VPC[Standard VPC Setup]
        STANDARD_VPC --> STANDARD_SUBNETS[Private + Optional Public Subnets]
        STANDARD_SUBNETS --> OPTIONAL_NAT[Optional NAT Gateway]
        OPTIONAL_NAT --> OPTIONAL_EP[Optional VPC Endpoints]
        OPTIONAL_EP --> STANDARD_EKS[Standard EKS Config]
        STANDARD_EKS --> CURRENT_NG[Current Node Group Setup]
        CURRENT_NG --> STANDARD_DEPLOY[Standard Deployment]
    end

    subgraph "Air-gap Path (Enhanced)"
        AIRGAP_PATH --> PRIVATE_VPC[Private VPC Only]
        PRIVATE_VPC --> PRIVATE_SUBNETS[Private Subnets Only]
        PRIVATE_SUBNETS --> NO_NAT[No NAT Gateway]
        NO_NAT --> COMPREHENSIVE_EP[Comprehensive VPC Endpoints]
        COMPREHENSIVE_EP --> AIRGAP_EKS[Air-gap EKS Config]
        AIRGAP_EKS --> DUAL_NG[Dual Node Groups]
        DUAL_NG --> VPN_SETUP[VPN Endpoint Setup]
        VPN_SETUP --> HELM_SETUP[Helm Integration]
        HELM_SETUP --> AIRGAP_DEPLOY[Air-gap Deployment]
    end

    %% Common Elements
    STANDARD_DEPLOY --> COMPLETE[Deployment Complete]
    AIRGAP_DEPLOY --> COMPLETE

    %% Shared Components (used by both paths)
    COMPLETE --> VALIDATE[Validate Deployment]
    VALIDATE --> OUTPUTS[Generate Outputs]
    OUTPUTS --> END[Finished]

    %% Styling
    classDef standard fill:#e1f5fe
    classDef airgap fill:#f3e5f5
    classDef common fill:#e8f5e8

    class STANDARD_PATH,STANDARD_VPC,STANDARD_SUBNETS,OPTIONAL_NAT,OPTIONAL_EP,STANDARD_EKS,CURRENT_NG,STANDARD_DEPLOY standard
    class AIRGAP_PATH,PRIVATE_VPC,PRIVATE_SUBNETS,NO_NAT,COMPREHENSIVE_EP,AIRGAP_EKS,DUAL_NG,VPN_SETUP,HELM_SETUP,AIRGAP_DEPLOY airgap
    class COMPLETE,VALIDATE,OUTPUTS,END common
```

## 8. Resource Dependency Graph

```mermaid
graph TD
    subgraph "Module Dependencies"
        subgraph "Root Module"
            MAIN[main.tf]
            VARIABLES[variables.tf]
            OUTPUTS[outputs.tf]
            PROVIDER[provider.tf]
        end

        subgraph "VPC Module"
            VPC_MAIN[vpc/main.tf]
            VPC_VARS[vpc/variables.tf]
            VPC_OUT[vpc/outputs.tf]
        end

        subgraph "EKS Module"
            EKS_MAIN[eks/main.tf]
            EKS_VARS[eks/variables.tf]
            EKS_OUT[eks/outputs.tf]
        end

        subgraph "New VPN Module"
            VPN_MAIN[vpn/main.tf]
            VPN_VARS[vpn/variables.tf]
            VPN_OUT[vpn/outputs.tf]
        end

        subgraph "Enhanced Components"
            ENDPOINTS_ENH[Enhanced VPC Endpoints]
            SG_ENH[Enhanced Security Groups]
            HELM_INT[Helm Integration]
            ECR_INT[Private ECR Integration]
        end
    end

    %% Data Flow Dependencies
    MAIN -->|cluster_type condition| ENHANCED_LOGIC

    subgraph "Enhanced Conditional Logic"
        ENHANCED_LOGIC[Conditional Logic Module]
        TYPE_CHECK[cluster_type Validation]
        PATH_SELECT[Path Selection Logic]
        CONFIG_MERGE[Configuration Merging]
    end

    ENHANCED_LOGIC --> TYPE_CHECK
    TYPE_CHECK --> PATH_SELECT
    PATH_SELECT --> CONFIG_MERGE

    %% Module Dependencies
    VARIABLES --> VPC_VARS
    VPC_VARS --> EKS_VARS
    EKS_VARS --> VPN_VARS

    MAIN --> VPC_MAIN
    VPC_MAIN -->|subnet_ids, vpc_id| EKS_MAIN
    VPC_MAIN -->|subnet_ids, sg_ids| VPN_MAIN

    EKS_MAIN -->|cluster_name, security_groups| HELM_INT
    VPN_MAIN -->|vpn_endpoint_id| EKS_MAIN

    %% Enhanced Components Dependencies
    VPC_MAIN -->|vpc_id, subnets| ENDPOINTS_ENH
    EKS_MAIN -->|cluster_security_group| SG_ENH
    SG_ENH -->|sg_rules| ENDPOINTS_ENH

    EKS_MAIN -->|cluster_endpoint| HELM_INT
    ENDPOINTS_ENH -->|ecr_endpoints| ECR_INT
    ECR_INT -->|private_repos| HELM_INT

    %% Output Dependencies
    VPC_OUT -->|vpc_info| MAIN
    EKS_OUT -->|cluster_info| MAIN
    VPN_OUT -->|vpn_config| MAIN

    %% Styling
    classDef existing fill:#fff3e0
    classDef enhanced fill:#e8f5e8
    classDef new fill:#e3f2fd

    class MAIN,VARIABLES,OUTPUTS,PROVIDER,VPC_MAIN,VPC_VARS,VPC_OUT,EKS_MAIN,EKS_VARS,EKS_OUT existing
    class ENHANCED_LOGIC,TYPE_CHECK,PATH_SELECT,CONFIG_MERGE,ENDPOINTS_ENH,SG_ENH,HELM_INT,ECR_INT enhanced
    class VPN_MAIN,VPN_VARS,VPN_OUT new
```
