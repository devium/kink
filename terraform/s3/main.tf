resource "aws_iam_user" "s3" {
  name = "${var.identifier}-s3"
}

resource "aws_iam_access_key" "s3" {
  user = aws_iam_user.s3.name
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl = "private"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.s3.arn}"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}",
        "arn:aws:s3:::${var.bucket_name}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:Get*",
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}/uploads/*"
      ]
    }
  ]
}
EOF

  tags = {
    Name = var.identifier
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = false
  restrict_public_buckets = false
}

resource "aws_iam_user_policy" "s3" {
  name = "${var.identifier}-s3"
  user = aws_iam_user.s3.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}",
        "arn:aws:s3:::${var.bucket_name}/*"
      ]
    }
  ]
}
EOF
}
