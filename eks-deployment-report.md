# EKS Deployment Report

## Cluster: `demo-cluster` (eu-central-1)

### 1. Fargate Profile Configuration

Recreated the Fargate profile (`demo-fargate-profile`) with a label selector so only pods with `scheduling: fargate` in the `default` namespace are scheduled on Fargate. This ensures MySQL and phpMyAdmin stay on EC2 nodes.

### 2. Nodegroup Upgrade

Replaced the original `t3.micro` nodegroup (`demo-nodes`) with a new `t3.small` nodegroup (`demo-nodes-small`, 3 nodes) to provide sufficient memory for MySQL.

### 3. EBS CSI Driver

- Associated an IAM OIDC provider with the cluster.
- Created an IAM role (`AmazonEKS_EBS_CSI_DriverRole`) for the EBS CSI driver.
- Installed the `aws-ebs-csi-driver` EKS addon to enable dynamic provisioning of `gp2` EBS volumes for MySQL persistence.

### 4. Docker Image (amd64)

Built and pushed a `linux/amd64` image (`alikakavand/demo-app:eks-amd64`) since the existing image was `arm64`-only and incompatible with Fargate.

### 5. Deployment via Helm

- **Java App** — `helm install my-java-app ./helm/my-java-app -f helm/eks-values.yaml` → 3 replicas on **Fargate**, exposed via LoadBalancer on port 8080.
- **MySQL** — `helm install mysql bitnami/mysql -f k8s-config/eks-mysql-values.yaml` → Primary + Secondary on **EC2** with 10Gi gp2 EBS volumes.
- **phpMyAdmin** — Included in the Java app chart, running on **EC2**, exposed via LoadBalancer on port 8081.

### Final State

| Component    | Replicas | Runs On   | Service Type  |
|--------------|----------|-----------|---------------|
| Java App     | 3        | Fargate   | LoadBalancer  |
| MySQL        | 1+1      | EC2       | ClusterIP     |
| phpMyAdmin   | 1        | EC2       | LoadBalancer  |
