provider "aws" {
  region = "ap-south-1"
}

variable "cidr" {
  default = "10.0.0.0/16"
}

resource "aws_key_pair" "nikki321" {
  key_name = "nikki321"
  public_key = file("/home/codespace/.ssh/id_rsa.pub")

  tags = {
    name = "nikki123"
  }
}

resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    name = "public_subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.myvpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_security_group" "firstSG" {
  name = "firstSG"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP for vpc"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "firstSG"
  }
}

resource "aws_instance" "naveen" {
  ami = "ami-03f4878755434977f"
  instance_type = "t2.micro"
  key_name = aws_key_pair.nikki321.key_name
  vpc_security_group_ids = [aws_security_group.firstSG.id]
  subnet_id = aws_subnet.public_subnet.id

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("/home/codespace/.ssh/id_rsa")
    host = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [ 
      
      "echo 'i am naveen ' ",
      
      
    ]
  }

}

resource "aws_launch_template" "nikki" {
  name_prefix   = "nikki"
  image_id      = "ami-03f4878755434977f"
  instance_type = "t2.micro"

}

resource "aws_autoscaling_group" "nikkiACS" {
  availability_zones = ["ap-south-1a"]
  desired_capacity = 1
  min_size = 1
  max_size = 1

  launch_template {
    id = aws_launch_template.nikki.id
    version = "$Latest"
  }
}
