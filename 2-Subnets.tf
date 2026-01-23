resource "aws_subnet" "public_subnet" {
  for_each = var.public_subnet

  vpc_id            = aws_vpc.vpc["myvpc"].id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  map_public_ip_on_launch = each.value.is_public

  tags = {
    Name    = "public_subnet-${each.key}"
    Network = "Public"
  }
}

#Route tables and IGW would be defined here for public subnets
#Do it ASAP Finish this!!!!





/* resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc["myvpc"].id
  cidr_block              = var.vpcs["myvpc"].subnet_cidrs["private_a"]
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name    = "private_subnet"
    Network = "Private"
  }
}
 */