# Kubernetes Deployment Checklist

A step-by-step checklist for containerizing and deploying a Java Spring Boot app to a Kubernetes cluster.

---

## 1. Build the Application JAR

- [ ] Ensure Gradle is installed (`gradle --version`)
- [ ] Fix dependencies in `build.gradle` if needed (e.g. correct Maven group IDs)
- [ ] Run `gradle bootJar` to produce the JAR under `build/libs/`
- [ ] Generate Gradle wrapper for future use: `gradle wrapper`

---

## 2. Build and Push the Docker Image

- [ ] Verify `Dockerfile` exists and references the correct JAR path
- [ ] Log in to Docker Hub: `docker login`
- [ ] Build the image with the Docker Hub repo tag:
  ```bash
  docker build -t <dockerhub-username>/<repo-name>:<tag> .
  ```
- [ ] Push the image to Docker Hub:
  ```bash
  docker push <dockerhub-username>/<repo-name>:<tag>
  ```

---

## 3. Set Up MySQL in the Cluster (via Helm)

- [ ] Add the Bitnami Helm repo:
  ```bash
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  ```
- [ ] Create `mysql-secret.yaml` with root, user, and replication passwords
- [ ] Apply the secret: `kubectl apply -f k8s-config/mysql-secret.yaml`
- [ ] Create `my-values.yaml` with Helm chart configuration (replication, auth, persistence)
- [ ] Install MySQL via Helm:
  ```bash
  helm install mysql bitnami/mysql -f k8s-config/my-values.yaml
  ```
- [ ] Verify MySQL pods are running: `kubectl get pods`

---

## 4. Create ConfigMap for App Configuration

- [ ] Create `mysql-configmap.yaml` with:
  - `DB_SERVER`: MySQL primary service name (e.g. `mysql-primary`)
  - `DB_NAME`: database name
  - `DB_USER`: database username
- [ ] Apply: `kubectl apply -f k8s-config/mysql-configmap.yaml`

---

## 5. Deploy the Java Application

- [ ] Create `my-java-app.yaml` with:
  - `Deployment` with 2 replicas
  - Container image pointing to your Docker Hub image
  - Environment variables (`DB_SERVER`, `DB_NAME`, `DB_USER`) from ConfigMap
  - `DB_PWD` from Secret
  - `imagePullSecrets` if Docker Hub repo is private
- [ ] Create Docker Hub pull secret (if repo is private):
  ```bash
  kubectl create secret docker-registry dockerhub-secret \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=<username> \
    --docker-password='<password>' \
    --docker-email=<email>
  ```
- [ ] Add a `ClusterIP` Service to `my-java-app.yaml` on port `8080`
- [ ] Apply: `kubectl apply -f k8s-config/my-java-app.yaml`
- [ ] Verify pods are running: `kubectl get pods`
- [ ] Check logs if pods fail: `kubectl logs <pod-name>`

---

## 6. Deploy phpMyAdmin (Optional — DB UI)

- [ ] Create `phpmyadmin.yaml` with:
  - `Deployment` with 1 replica using `phpmyadmin:5.2` image
  - `PMA_HOST`, `PMA_USER` from ConfigMap; `PMA_PASSWORD` from Secret
  - `ClusterIP` Service on port `8081`
- [ ] Apply: `kubectl apply -f k8s-config/phpmyadmin.yaml`
- [ ] Access via port-forward:
  ```bash
  kubectl port-forward service/phpmyadmin-service 8081:8081
  ```
- [ ] Open `http://localhost:8081` in browser

---

## 7. Install Nginx Ingress Controller (via Helm)

- [ ] Add the ingress-nginx Helm repo:
  ```bash
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo update
  ```
- [ ] Clean up any pre-existing raw-manifest ingress-nginx resources:
  ```bash
  kubectl delete namespace ingress-nginx
  kubectl delete clusterrole ingress-nginx ingress-nginx-admission
  kubectl delete clusterrolebinding ingress-nginx ingress-nginx-admission
  kubectl delete ingressclass nginx
  kubectl delete validatingwebhookconfiguration ingress-nginx-admission
  ```
- [ ] Install via Helm:
  ```bash
  helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace
  ```
- [ ] Verify controller pod is running: `kubectl get pods -n ingress-nginx`

---

## 8. Configure Ingress for the Application

- [ ] Create `ingress.yaml` with:
  - `ingressClassName: nginx`
  - Host rule pointing `my-java-app.com` to `my-java-app-service:8080`
- [ ] Apply: `kubectl apply -f k8s-config/ingress.yaml`
- [ ] Verify: `kubectl get ingress`

---

## 9. Expose the Cluster (Minikube only)

- [ ] Run in a separate terminal and keep it running:
  ```bash
  minikube tunnel
  ```
  Enter your macOS password when prompted.
- [ ] Get the assigned external IP:
  ```bash
  kubectl get svc -n ingress-nginx
  ```
- [ ] Map the domain to the external IP in `/etc/hosts`:
  ```bash
  echo "127.0.0.1  my-java-app.com" | sudo tee -a /etc/hosts
  ```
- [ ] Open `http://my-java-app.com/get-data` in browser and verify response

---

## Quick Reference — Key Commands

```bash
# Build JAR
gradle bootJar

# Build & push Docker image
docker build -t <user>/<repo>:<tag> .
docker push <user>/<repo>:<tag>

# Apply all k8s configs
kubectl apply -f k8s-config/

# Check pod status
kubectl get pods

# Check pod logs
kubectl logs <pod-name>

# Port-forward a service
kubectl port-forward service/<service-name> <local-port>:<service-port>

# Minikube tunnel (keep running)
minikube tunnel
```
