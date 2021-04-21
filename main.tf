provider "aws" {
  region     = var.my_region
  access_key = var.my_key
  secret_key = var.my_s_key
}

# Create VPC

resource "aws_vpc" "prod-vpc" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

# Create IGW

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

# Create Custom Route Table

resource "aws_route_table" "prod-route-table" {
   vpc_id = aws_vpc.prod-vpc.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.gw.id
   }

   route {
     ipv6_cidr_block = "::/0"
     gateway_id      = aws_internet_gateway.gw.id
   }
   tags = {
     Name = "Prod"
}
}

# Create Subnet

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
   tags = {
     Name = "prod-subnet"
   }
}

# Associate Subnet in Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# Create Security Group and allow port 22, 80 and 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_trafic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# Create a network interface with an IP in the subnet that created


resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# Assign Elastic IP

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

# Create Ubuntu server and install apache2

resource "aws_instance" "my-server" {
  ami = var.my-ami-id
  instance_type = "t3.micro"
  availability_zone = "eu-north-1a"
  key_name = "atg-keypair"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

   user_data = "${file(install_apache.sh)}"

   tags = {
    "Name" = "Ubuntu-server"
  }
}
