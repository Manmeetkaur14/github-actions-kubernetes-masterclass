#!/bin/bash
set -e

ENV=${1:-dev}
AWS_REGION="ap-south-1"
CLUSTER_NAME="skillpulse-dev"
PROJECT_ROOT="$HOME/github-actions-kubernetes-masterclass"

echo "======================================"
echo "Starting SkillPulse Deployment"
echo "Environment: $ENV"
echo "======================================"

# Step 1: Terraform Infrastructure
echo "Step 1: Deploying Terraform infrastructure..."
cd $PROJECT_ROOT/terraform/environments/$ENV

terraform init
terraform apply --auto-approve

# Step 2: Update kubeconfig
echo "Step 2: Updating kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Step 3: Install EBS CSI driver
echo "Step 3: Installing EBS CSI driver..."
aws eks create-addon \
  --cluster-name $CLUSTER_NAME \
  --addon-name aws-ebs-csi-driver \
  --region $AWS_REGION || true

# Step 4: Wait a bit
sleep 30

# Step 5: Deploy Kubernetes manifests
echo "Step 4: Deploying Kubernetes manifests..."
cd $PROJECT_ROOT

kubectl apply -f k8s/core/
kubectl apply -f k8s/mysql/
kubectl apply -f k8s/skillpulse/

# Step 6: Fix backend image
kubectl set image deployment/backend \
backend=486036174293.dkr.ecr.ap-south-1.amazonaws.com/skillpulse-backend:latest \
-n skillpulse || true

# Step 7: Fix frontend image
kubectl set image deployment/frontend \
frontend=486036174293.dkr.ecr.ap-south-1.amazonaws.com/skillpulse-frontend:latest \
-n skillpulse || true

# Step 8: Wait for rollout
echo "Step 5: Waiting for deployments..."
kubectl rollout status deployment/backend -n skillpulse --timeout=300s
kubectl rollout status deployment/frontend -n skillpulse --timeout=300s
kubectl rollout status statefulset/mysql -n skillpulse --timeout=300s

echo "======================================"
echo "Deployment Completed Successfully!"
echo "======================================"

kubectl get pods -n skillpulse
kubectl get svc -n skillpulse
