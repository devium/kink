output "bucket_name" {
  value = var.bucket_name
}

output "access_key_id" {
  sensitive = true
  value = aws_iam_access_key.s3.id
}

output "access_key_secret" {
  sensitive = true
  value = aws_iam_access_key.s3.secret
}
