#!/bin/bash
apt-get update -y

# Install required packages
apt-get install -y curl wget jq git unzip

# Install kubectl
curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
/bin/mv ./kubectl /usr/local/bin
kubectl version --client

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Google Cloud SDK
apt-get install -y apt-transport-https ca-certificates gnupg
/bin/echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update && apt-get install -y google-cloud-sdk

# Configure gcloud and kubectl for GKE
if [ -n "${cluster_name}" ]; then
    gcloud container clusters get-credentials ${cluster_name} --region ${region}
fi

# Create a helper script for GKE access
cat > /root/gke-connect.sh << 'EOF'
#!/bin/bash
echo "Connecting to GKE cluster: ${cluster_name}"
gcloud container clusters get-credentials ${cluster_name} --region ${region}
kubectl get nodes
EOF

chmod +x /root/gke-connect.sh

echo "Bastion host setup completed!"
