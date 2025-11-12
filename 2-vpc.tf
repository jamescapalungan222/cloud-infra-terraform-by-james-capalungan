data "aws_vpc" "main" {
    id = "vpc-0a16918d8b440fc83"
}

output "vpc_cidr" {
    value = data.aws_vpc.main.cidr_block
}

