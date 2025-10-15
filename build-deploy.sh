#! /bin/bash
# Build and deploy the applications and Nginx reverse proxy to Kubernetes
cd k8s-reverse-proxy-auth-ssl/
mkdir -p nginx/certs

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout nginx/certs/localhost.key \
  -out nginx/certs/localhost.crt \
  -subj "/CN=localhost/O=LocalDev"

# Authentication setup
# Install apache2-utils if not already installed (for htpasswd command)

sudo apt-get update
sudo apt-get install -y apache2-utils
# Create a password file with a user (change 'admin' and 'password' as needed)
htpasswd -cb nginx/htpasswd admin password  

# Build Docker images
docker build -t ibrahimmintal/node-app1:latest ./app1
docker build -t ibrahimmintal/node-app2:latest ./app2
docker build -t ibrahimmintal/nginx-reverse-proxy:latest ./nginx
# Push Docker images to Docker Hub (or your preferred registry)
docker push ibrahimmintal/node-app1:latest
docker push ibrahimmintal/node-app2:latest
docker push ibrahimmintal/nginx-reverse-proxy:latest


# Deploy to Kubernetes
minikube start
docker login


# Create secrets for SSL certs and htpasswd
kubectl create secret tls nginx-certs \
  --cert=nginx/certs/localhost.crt \
  --key=nginx/certs/localhost.key \
  --dry-run=client -o yaml | kubectl apply -f -

  kubectl create secret generic nginx-htpasswd \
  --from-file=.htpasswd=nginx/.htpasswd \
  --dry-run=client -o yaml | kubectl apply -f -


# Apply Kubernetes manifests
kubectl apply -f k8s/app1-deployment.yml
kubectl apply -f k8s/app2-deployment.yml
kubectl apply -f k8s/proxy-deployment.yml
kubectl apply -f k8s/proxy-service.yml
kubectl apply -f k8s/app1-service.yml
kubectl apply -f k8s/app2-service.yml
kubectl apply -f k8s/proxy-ConfigMap.yml


# Wait until all pods are in the 'Running' state
while [[ $(kubectl get pods --field-selector=status.phase!=Running | wc -l) -gt 1 ]]; do
  echo "Some pods are not yet running. Waiting..."
  sleep 5
done


# Verify deployments
kubectl get pods
kubectl get services


# Access the Nginx reverse proxy
minikube service nginx-service --url

