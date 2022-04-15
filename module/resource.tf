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

resource "aws_route_table" "priRT"{
    vpc_id = aws_vpc.vpc.id 
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.NAT.id 
        }
    tags = {
           Name = "${var.env_prefix}-pri" 
    }
}

resource "aws_route_table" "pubRT"{
    vpc_id = aws_vpc.vpc.id 
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
           Name = "${var.env_prefix}-pub" 
    }
}


resource "aws_route_table_association" "RTA" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.priRT.id
}

resource "aws_route_table_association" "RTA1" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.pubRT.id
}

resource "aws_security_group" "ssh-sg" {
  name        = "ssh-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}
data "aws_ami" "latest-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    } 
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    } 
}
output "aws_ami_id" {
  value = data.aws_ami.latest-linux-image.id
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
  
}
resource "aws_instance" "ec2"{
    ami = data.aws_ami.latest-linux-image.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.public.id
    key_name = aws_key_pair.ssh-key.id
    security_groups = [aws_security_group.ssh-sg.id]
    associate_public_ip_address = true
    
    tags = {
        Name =  "${var.env_prefix}-ec2"
    }
}