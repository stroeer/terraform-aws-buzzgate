output "ecr_repo_arn" {
  description = "ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "public_dns" {
  description = "Public DNS entry."
  value       = "${aws_route53_record.external.name}.${data.aws_route53_zone.external.name}"
}

output "private_dns" {
  description = "Private DNS entry."
  value       = "${aws_route53_record.internal.name}.${data.aws_route53_zone.internal.name}"
}

output "kinesis_firehose_delivery_stream_name" {
  description = "The name of the Kinesis Firehose delivery stream."
  value       = module.logs.kinesis_firehose_delivery_stream_name
}
