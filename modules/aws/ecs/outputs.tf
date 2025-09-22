output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "service_name" {
  description = "Name of the ECS service (created in main module)"
  value       = var.cluster_name
}

output "security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "certificate_arn" {
  description = "ARN of the certificate (either provided or self-signed)"
  value       = var.acm_certificate_arn != null ? var.acm_certificate_arn : (var.create_self_signed_cert ? aws_acm_certificate.self_signed[0].arn : null)
}

output "secrets_endpoint" {
  description = "Endpoint for accessing secrets via sidecar"
  value       = "http://localhost:8080"
}