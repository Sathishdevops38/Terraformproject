resource "aws_vpc" "vpc"{
   cidr_block = var.cidr_block
   instance_tenancy = "default"
    
    tags ={
        "Name" = "${var.env_prefix}-vpc"
    }

}

resource "aws_subnet" "private"{
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.private_block

    tags ={
        "Name" = "${var.env_prefix}-private"
    }
}


resource "aws_subnet" "public"{
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.public_block
    map_public_ip_on_launch = true

    tags ={
        "Name" = "${var.env_prefix}-public"
    }
}

resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.vpc.id

    tags ={
        "Name" = "${var.env_prefix}-igw"
    }
}
/*
resource "aws_internet_gateway_attachment" "igwa" {
  internet_gateway_id = aws_internet_gateway.igw.id
  vpc_id              = aws_vpc.vpc.id
}
*/
resource "aws_eip" "eip"{
    vpc = true 

    tags ={
        "Name" = "${var.env_prefix}-eip"
    }
}

resource "aws_nat_gateway" "NAT" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.private.id

  tags = {
    Name = "${var.env_prefix}-NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}
