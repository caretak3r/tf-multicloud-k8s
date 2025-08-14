#!/bin/bash
yum update -y

# Install required packages
yum install -y awscli curl wget jq git unzip

# Install kubectl
curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --client

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install session manager plugin
yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure AWS CLI and kubectl for EKS
if [ -n "${cluster_name}" ]; then
    aws eks update-kubeconfig --region ${region} --name ${cluster_name}
fi

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/bastion/${cluster_name}",
                        "log_stream_name": "{instance_id}/var/log/messages"
                    },
                    {
                        "file_path": "/var/log/secure",
                        "log_group_name": "/aws/ec2/bastion/${cluster_name}",
                        "log_stream_name": "{instance_id}/var/log/secure"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create a helper script for EKS access
cat > /home/ec2-user/eks-connect.sh << 'EOF'
#!/bin/bash
echo "Connecting to EKS cluster: ${cluster_name}"
aws eks update-kubeconfig --region ${region} --name ${cluster_name}
kubectl get nodes
EOF

chmod +x /home/ec2-user/eks-connect.sh
chown ec2-user:ec2-user /home/ec2-user/eks-connect.sh

echo "Bastion host setup completed!"