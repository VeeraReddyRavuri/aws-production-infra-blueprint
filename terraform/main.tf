# Install hashicorp/aws and set region to ap-south-1
provider "aws" {
    region = "ap-south-1"
}

#Create a VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr

    tags = {
        Name = "${var.env}-vpc"
    }
}

# Create public subnet
resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.env}-public-subnet"
    }
}

# Create private subnet
resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"

    tags = {
        Name = "${var.env}-private-subnet"
    }
}

# create internet gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.env}-igw"
    }
}

# create a route table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.env}-public-rt"
    }
}

# create a route table tule to access public internt through igw
resource "aws_route" "public_internet" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

# associate the route table to public subnet
resource "aws_route_table_association" "public_association" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

# create a security group for NAT
resource "aws_security_group" "nat_sg" {
    name = "nat-sg"
    description = "Allow traffic from private subnet"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create a Nat instacne using t3.micro
resource "aws_instance" "nat" {
    ami = "ami-0f5ee92e2d63afc18" # Amazon Linux (ap-south-1)
    instance_type = "t3.micro"
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.nat_sg.id]
    associate_public_ip_address = true

    source_dest_check = false

    key_name = aws_key_pair.main.key_name

    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

    tags = {
      Name = "${var.env}-nat-instance"
    }
}

# create a route table for private subnet
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.env}-private-rt"
    }  
}

# create a rule for Nat to allow outbound traffic
resource "aws_route" "private_internet" {
    route_table_id = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
}

# asscoiate the route table with private subnet
resource "aws_route_table_association" "private_association" {
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.private.id  
}

# TO connect to NAT instance, we need ssh access, so we add key pair
resource "aws_key_pair" "main" {
    key_name = "${var.env}-devops-key"
    public_key = file("/home/veera/.ssh/id_rsa.pub")
}

resource "aws_security_group" "private_sg" {
    name = "private-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.bastion_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create a Private EC2 instance
resource "aws_instance" "private_ec2" {
    ami = "ami-0f5ee92e2d63afc18"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.private.id
    vpc_security_group_ids = [aws_security_group.private_sg.id]
    key_name = aws_key_pair.main.key_name

    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

    tags = {
      Name = "${var.env}-private-ec2"
    }
}

# Create Bastion Host
resource "aws_security_group" "bastion_sg" {
    name = "bastion-sg"
    description = "Allow SSH from your IP"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create a bstion instance
resource "aws_instance" "bastion" {
    ami = "ami-0f5ee92e2d63afc18"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.bastion_sg.id]
    associate_public_ip_address = true
    key_name = aws_key_pair.main.key_name

    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

    tags = {
        Name = "${var.env}-bastion-host"
    }
}