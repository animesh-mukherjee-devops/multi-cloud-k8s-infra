resource "aws_s3_bucket" "tfstate" {
  bucket = var.spaces_bucket_name
}

resource "aws_s3_bucket_acl" "tfstate_acl" {
  bucket = aws_s3_bucket.tfstate.id
  acl    = "private"
}
