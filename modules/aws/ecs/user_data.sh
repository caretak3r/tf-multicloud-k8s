#!/bin/bash

# ECS Agent configuration
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true" >> /etc/ecs/ecs.config

# Optimize Docker settings for ECS
echo "ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=5m" >> /etc/ecs/ecs.config
echo "ECS_IMAGE_CLEANUP_INTERVAL=10m" >> /etc/ecs/ecs.config
echo "ECS_IMAGE_MINIMUM_CLEANUP_AGE=30m" >> /etc/ecs/ecs.config

# Update packages and install CloudWatch agent
yum update -y
yum install -y amazon-cloudwatch-agent

# Start and enable ECS agent
systemctl enable ecs
systemctl start ecs

# Install ECS CLI tools
curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
chmod +x /usr/local/bin/ecs-cli

# Set up log forwarding for ECS agent
cat << 'EOF' > /etc/rsyslog.d/51-ecs-agent.conf
# ECS Agent logs
$FileCreateMode 0644
$DirCreateMode 0755
$Umask 0022
$PrivDropToUser ecs
$PrivDropToGroup ecs
:programname, isequal, "ecs-agent" /var/log/ecs/ecs-agent.log
& stop
EOF

systemctl restart rsyslog