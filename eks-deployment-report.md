# EKS Deployment Report — Project Overview

## Cluster: `demo-cluster` (eu-central-1)

A Java Gradle web app deployed on EKS with a CI/CD pipeline (Jenkins) that builds, pushes to ECR, and deploys via Helm.

---

### 1. Infrastructure Setup

- **Fargate profile** (`demo-fargate-profile`) — label selector `scheduling: fargate` in the `default` namespace. Only the Java app pods run on Fargate; MySQL and phpMyAdmin stay on EC2.
- **Nodegroup** — replaced `t3.micro` (`demo-nodes`) with `t3.small` (`demo-nodes-small`, 3 nodes) for sufficient MySQL memory.
- **EBS CSI Driver** — IAM OIDC provider + `AmazonEKS_EBS_CSI_DriverRole` + `aws-ebs-csi-driver` addon for dynamic `gp2` volume provisioning.

### 2. Container Registry (ECR)

- **Registry:** `320806842529.dkr.ecr.eu-central-1.amazonaws.com`
- **Repository:** `java-gradle-app-exec11`
- Initially used DockerHub (`alikakavand/demo-app`), migrated to ECR for native AWS integration.
- ECR auth is handled by IAM roles — no `imagePullSecrets` needed on EKS.

### 3. CI/CD Pipeline (Jenkins)

Pipeline stages (`Jenkinsfile`):

1. **Increment version** — bumps patch version in `build.gradle`, sets `IMAGE_VERSION`.
2. **Build app** — `./gradlew clean build`.
3. **Build & push image** — builds Docker image, authenticates to ECR, pushes `java-gradle-app-exec11:<version>-<build>`.
4. **Deploy** — `aws eks update-kubeconfig` → `helm upgrade --install` with `--set image.tag`.
5. **Commit version bump** — pushes updated `build.gradle` back to GitHub.

### 4. Deployment via Helm

- **Manual/full deploy:** `helmfile -f k8s-config/eks-helmfile.yaml sync` (deploys Java app + MySQL together).
- **CI deploy (Jenkins):** `helm upgrade --install my-jg-app ./helm/my-java-app -f helm/eks-values.yaml --set image.tag=<version>`

### 5. Final State

| Component    | Replicas | Runs On   | Image Source | Service Type  |
|--------------|----------|-----------|--------------|---------------|
| Java App     | 3        | Fargate   | ECR          | LoadBalancer  |
| MySQL        | 1+1      | EC2       | DockerHub    | ClusterIP     |
| phpMyAdmin   | 1        | EC2       | DockerHub    | LoadBalancer  |
