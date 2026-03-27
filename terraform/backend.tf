terraform {
  backend "s3" {
    bucket = "ai-infra-tf-state-bucket-202601"
    key = "${var.env}/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "terraform-lock"    
  } 
}

#resource "aws_s3_bucket" "tf_state" {
#    bucket = "ai-infra-tf-state-bucket-202601"

#    tags = {
 #       Name = "terraform-state"
  #  }
#}

#resource "aws_s3_bucket_versioning" "versioning" {
#    bucket = aws_s3_bucket.tf_state.id

#    versioning_configuration {
#        status = "Enabled"
 #   }
#}

#resource "aws_dynamodb_table" "tf_lock" {
#    name = "terraform-lock"
#    billing_mode = "PAY_PER_REQUEST"
#    hash_key = "LockID"

#    attribute {
#      name = "LockID"
#      type = "S"
#    }
#}