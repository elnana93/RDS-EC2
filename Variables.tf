
# Region variable for AWS provider

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-west-2"
}

#VPC's

/* variable "vpcs" {
  description = "A map defining the name, CIDR block, and tags for each VPC."
  type = map(object({
    cidr_block = string
    tags       = map(string)
  }))

  default = {
    app1 = {
      cidr_block = "10.50.0.0/16"
      tags       = {
        Name        = "myvpc"
        Environment = "RDS-VPC"
      }
    }
  }
} */


variable "vpcs" {
  description = "A map defining the name, CIDR block, and tags for each VPC."
  type = map(object({
    cidr_block = string
    tags       = map(string)
  }))
  default = {
    myvpc = {
      cidr_block = "10.50.0.0/16"
      tags       = { Name = "myvpc", Environment = "vpc4RDS" }
    }
  }
}


variable "public_subnet" {
  description = "Configuration for the public subnets in the VPC."
  type = map(object({
    cidr_block = string
    az         = string
    is_public  = bool
  }))
  default = {
    "public_a" = { cidr_block = "10.50.1.0/24", az = "us-west-2a", is_public = true }
    "public_b" = { cidr_block = "10.50.2.0/24", az = "us-west-2b", is_public = true }
    "public_c" = { cidr_block = "10.50.3.0/24", az = "us-west-2c", is_public = true }
  }
}


variable "private_subnet" {
  description = "Configuration for the private subnets in the VPC."
  type = map(object({
    cidr_block = string
    az         = string
    is_public  = bool
  }))
  default = {
    "private_a" = { cidr_block = "10.50.11.0/24", az = "us-west-2a", is_public = false }
    "private_b" = { cidr_block = "10.50.12.0/24", az = "us-west-2b", is_public = false }
    "private_c" = { cidr_block = "10.50.13.0/24", az = "us-west-2c", is_public = false }
  }
}

