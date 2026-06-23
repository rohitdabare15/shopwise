#!/bin/bash
set -e

exec > >(tee /var/log/jenkins-install.log) 2>&1
echo "Starting Jenkins installation at $(date)"

# Update system
dnf update -y --skip-broken

# Install Java 21 (Jenkins 2.555+ requires Java 21 minimum)
dnf install -y java-21-amazon-corretto git unzip fontconfig

# Set Java 21 as default
alternatives --set java /usr/lib/jvm/java-21-amazon-corretto.x86_64/bin/java

# Install Jenkins repo manually (curl redirect workaround)
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

tee /etc/yum.repos.d/jenkins.repo << 'REPO'
[jenkins]
name=Jenkins
baseurl=https://pkg.jenkins.io/redhat-stable
gpgcheck=0
enabled=1
REPO

dnf install -y jenkins --nogpgcheck

# Configure Jenkins to use Java 21
mkdir -p /etc/systemd/system/jenkins.service.d
tee /etc/systemd/system/jenkins.service.d/override.conf << 'CONF'
[Service]
Environment="JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto.x86_64"
CONF

# Install Docker
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker jenkins

# Install AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# Install kubectl v1.31
curl -fsSL -o /tmp/kubectl \
  "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl"
chmod +x /tmp/kubectl
mv /tmp/kubectl /usr/local/bin/

# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Configure kubectl for EKS
aws eks update-kubeconfig \
  --region ${aws_region} \
  --name ${cluster_name} || echo "EKS kubeconfig will be configured manually"

# Copy kubeconfig to Jenkins home
mkdir -p /var/lib/jenkins/.kube
if [ -f /root/.kube/config ]; then
  cp /root/.kube/config /var/lib/jenkins/.kube/config
  chown -R jenkins:jenkins /var/lib/jenkins/.kube
fi

# Start Jenkins
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# Wait for password file
echo "Waiting for Jenkins to initialise..."
for i in $$(seq 1 30); do
  if [ -f /var/lib/jenkins/.jenkins/secrets/initialAdminPassword ]; then
    echo "Jenkins is ready"
    break
  fi
  sleep 10
  echo "Waiting... attempt $$i of 30"
done

echo "Jenkins installation complete at $(date)"
cat /var/lib/jenkins/.jenkins/secrets/initialAdminPassword || echo "Check manually"
