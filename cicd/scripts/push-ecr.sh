#!/bin/bash
# push-ecr.sh — authenticates to ECR and pushes tagged images
# Called by Jenkins pipeline after docker build

set -e

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_TAG=${IMAGE_TAG:-latest}
GIT_SHA=${GIT_SHA:-$(git rev-parse --short HEAD)}

echo "Pushing to registry: $ECR_REGISTRY"
echo "Image tag: $IMAGE_TAG"

# Authenticate
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Push backend
docker tag shopwise-backend:local $ECR_REGISTRY/shopwise/backend:$IMAGE_TAG
docker tag shopwise-backend:local $ECR_REGISTRY/shopwise/backend:$GIT_SHA
docker push $ECR_REGISTRY/shopwise/backend:$IMAGE_TAG
docker push $ECR_REGISTRY/shopwise/backend:$GIT_SHA

# Push frontend
docker tag shopwise-frontend:local $ECR_REGISTRY/shopwise/frontend:$IMAGE_TAG
docker tag shopwise-frontend:local $ECR_REGISTRY/shopwise/frontend:$GIT_SHA
docker push $ECR_REGISTRY/shopwise/frontend:$IMAGE_TAG
docker push $ECR_REGISTRY/shopwise/frontend:$GIT_SHA

echo "Push complete"
echo "Backend:  $ECR_REGISTRY/shopwise/backend:$IMAGE_TAG"
echo "Frontend: $ECR_REGISTRY/shopwise/frontend:$IMAGE_TAG"
