output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "bastion_security_group_id" {
  description = "Security group ID of the bastion host"
  value       = aws_security_group.bastion.id
}

output "bastion_iam_role_arn" {
  description = "IAM role ARN of the bastion host"
  value       = aws_iam_role.bastion.arn
}

output "ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.bastion.public_ip}"
}

output "session_manager_command" {
  description = "AWS CLI command to connect via Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id}"
}

output "eks_connect_command" {
  description = "Command to run on bastion host to configure kubectl for EKS"
  value       = "./eks-connect.sh"
}