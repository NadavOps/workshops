output "commands" {
  value = [
    "aws --profile ${var.aws_provider_profile} --region ${var.aws_provider_default_region} eks update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}",
    "aws --profile ${var.aws_provider_profile} --region ${var.aws_provider_default_region} eks get-token --cluster-name ${module.eks.cluster_name}"
  ]
}
