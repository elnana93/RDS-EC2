


terraform {
  backend "s3" {
    bucket = "e5statefiles"
    key    = "e5realestate/terraform.tfstate"
    region = "us-west-2" # <--- MAKE SURE THIS MATCHES YOUR BUCKET REGION

    dynamodb_table = "e5statefiles-locks" # This tells Terraform where to find the lock
    encrypt        = true
  }
} 