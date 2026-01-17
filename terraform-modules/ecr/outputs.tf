output "repository_arn" {
  description = "All outputs of the repository."
  value       = module.ecr.repository_arn
}

output "repository_registry_id" {
  description = "The attached repository policies."
  value       = module.ecr.repository_registry_id
}

output "repository_url" {
  description = "The attached repository lifecycle policies."
  value       = module.ecr.repository_url
}