output "bastion_host_name" {
  description = "The name of the bastion host."
  value       = one(google_compute_instance.bastion[*].name)
}

output "bastion_host_internal_ip" {
  description = "The internal IP address of the bastion host."
  value       = one(google_compute_instance.bastion[*].network_interface[0].network_ip)
}

output "bastion_host_public_ip" {
  description = "The public IP address of the bastion host."
  value       = one(google_compute_instance.bastion[*].network_interface[0].access_config[0].nat_ip)
}
