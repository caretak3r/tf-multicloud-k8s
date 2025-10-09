output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.main.version
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS worker nodes"
  value       = aws_security_group.nodes.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS worker nodes"
  value       = aws_iam_role.nodes.arn
}

output "main_node_group_arn" {
  description = "EKS main application node group ARN"
  value       = aws_eks_node_group.main_app.arn
}

output "main_node_group_status" {
  description = "EKS main application node group status"
  value       = aws_eks_node_group.main_app.status
}

output "general_node_group_arn" {
  description = "EKS general purpose node group ARN"
  value       = aws_eks_node_group.general_purpose.arn
}

output "general_node_group_status" {
  description = "EKS general purpose node group status"
  value       = aws_eks_node_group.general_purpose.status
}

output "node_groups" {
  description = "Information about all node groups"
  value = {
    main = {
      arn    = aws_eks_node_group.main_app.arn
      status = aws_eks_node_group.main_app.status
      name   = aws_eks_node_group.main_app.node_group_name
      type   = "main-application"
    }
    general = {
      arn    = aws_eks_node_group.general_purpose.arn
      status = aws_eks_node_group.general_purpose.status
      name   = aws_eks_node_group.general_purpose.node_group_name
      type   = "general-purpose"
    }
  }
}

output "oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig for EKS (requires bastion or VPN access)"
  value       = "aws eks update-kubeconfig --region ${data.aws_caller_identity.current.account_id} --name ${var.cluster_name}"
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for EKS cluster encryption"
  value       = local.kms_key_arn
}
