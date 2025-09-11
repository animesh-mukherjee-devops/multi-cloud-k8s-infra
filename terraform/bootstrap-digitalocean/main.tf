resource "aws_s3_bucket" "tfstate" {
  bucket = var.spaces_bucket_name
  acl    = "private"
}
