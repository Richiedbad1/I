provider "aws" {
	region = "us-east-1"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "zone" {}
variable "instance_type" {}
variable "key_location" {}

resource "aws_vpc" "richard-vpc" {
	cidr_block = "10.0.0.0/16"
	tags = {
		Name = "richard"
	}
}

resource "aws_subnet" "richard-subnet-1" {
	vpc_id = aws_vpc.richard-vpc.id
	cidr_block = var.subnet_cidr_block
	availability_zone = var.zone
	tags = {
		Name: "richard_subnet"
	}
}
resource "aws_internet_gateway" "richard-igw" {
    vpc_id = aws_vpc.richard-vpc.id
    tags = {
        Name: "richard-igw"
    }
}

resource "aws_default_route_table" "richard-main-rt" {
    default_route_table_id = aws_vpc.richard-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.richard-igw.id
    }
    tags = {
        Name: "richard-main-rt"
    }
}

resource "aws_default_security_group" "richard-default-sg" {
    vpc_id = aws_vpc.richard-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
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
        Name: "richard-default-sg"
    }
}

data "aws_ami" "latest_image" {
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

resource "aws_key_pair" "richard-key" {
    key_name = "richard-server"
    public_key = file(var.key_location)
}

resource "aws_instance" "richard-server" {
    ami = data.aws_ami.latest_image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.richard-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.richard-default-sg.id]
    availability_zone = var.zone

    associate_public_ip_address = true
    key_name = aws_key_pair.richard-key.key_name

    user_data = file("entry-script.sh")

    tags = {
    	Name: "richard-server"
    }
}

output "server_ip_address" {
    value = aws_instance.richard-server.public_ip
}

output "aws_ami_id" {
    value = data.aws_ami.latest_image.id
}
