resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    "Name" = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp_vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.az
  tags = {
    "Name" = "${var.env_prefix}-subnet-1"
  }
}
/*
resource "aws_route_table" "myapp-RT" {
    vpc_id = aws_vpc.myapp_vpc.id

    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
      "Name" = "${var.env_prefix}-RT"
    }
}
*/
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp_vpc.id
  tags = {
    "Name" = "${var.env_prefix}-igw"
  }
}
/*
resource "aws_route_table_association" "myapp-subnet-ass" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-RT.id
}
*/
resource "aws_default_route_table" "mainrtb" {
  default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id
  route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
      "Name" = "${var.env_prefix}-RT"
    }
}
/*
resource "aws_security_group" "myapp-sg" {
  name= "myapp-sg"
  vpc_id = aws_vpc.myapp_vpc.id

  ingress  {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [var.my_ip]
  }
  ingress  {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = [var.my_ip]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [var.my_ip]
      prefix_list_ids = []
  }

  tags = {
    "Name" = "${var.env_prefix}-sg"
  }
}
*/

resource "aws_default_security_group" "myapp-sg" {
  vpc_id = aws_vpc.myapp_vpc.id

  ingress  {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [var.my_ip]
  }
  ingress  {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = [var.my_ip]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [var.my_ip]
      prefix_list_ids = []
  }

  tags = {
    "Name" = "${var.env_prefix}-sg"
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

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-linux-image.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.myapp-sg.id]
  availability_zone = var.az
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.id

  user_data = <<EOF
                  #!/bin/bash
                  sudo yum update -y && sudo yum install docker -y
                  sudo systemctl start docker
                  sudo systemctl enable docker 
                  sudo usermod -aG docker ec2-user
                  docker run -p 8080:80 nginx
              EOF

  tags = {
    "Name" = "${var.env_prefix}-server"
  }
}

output "my_instance_private_ip" {
  value = aws_instance.myapp-server.private_ip
}
output "my_instnace_public_ip" {
  value = aws_instance.myapp-server.public_ip
  
}

