
provider "aws" {
    region = "us-east-2"
}
  
resource "aws_vpc" "kubernetes-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
} 
resource "aws_subnet" "kubernetes-subnet-1" {
  vpc_id = aws_vpc.kubernetes-vpc.id 
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone 
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

resource "aws_route_table" "kubernetes-route-table" {
    vpc_id = aws_vpc.kubernetes-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.kubernetes-igw.id
    }
    tags = {
    Name: "${var.env_prefix}-rtb"
  }
}

  resource "aws_internet_gateway" "kubernetes-igw" {
    vpc_id = aws_vpc.kubernetes-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.kubernetes-subnet-1.id
    route_table_id = aws_route_table.kubernetes-route-table.id 
}

resource "aws_security_group" "kubernetes-sg" {
    name = "kubernetes-sg"
    vpc_id = aws_vpc.kubernetes-vpc.id
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-sg"
    }
}
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
}
        
resource "aws_instance" "master-node" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.kubernetes-subnet-1.id
    vpc_security_group_ids = [aws_security_group.kubernetes-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("install-docker-script.sh")

    tags = {
        Name: "${var.env_prefix}-master"
    }
}

resource "aws_instance" "worker1-node" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.kubernetes-subnet-1.id
    vpc_security_group_ids = [aws_security_group.kubernetes-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

   user_data = file("install-docker-script.sh")

    tags = {
        Name: "${var.env_prefix}-worker1"
    }
}

resource "aws_instance" "worker2-node" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.kubernetes-subnet-1.id
    vpc_security_group_ids = [aws_security_group.kubernetes-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

   user_data = file("install-docker-script.sh")

    tags = {
        Name: "${var.env_prefix}-worker2"
    }
}
