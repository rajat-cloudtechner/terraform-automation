resource "aws_vpc" "Main" {                
   cidr_block       = "${var.main_vpc_cidr}"    
   instance_tenancy = "default"
   enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
 }

 resource "aws_subnet" "publicsubnets" {    
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.public_subnets}"
   availability_zone = "${var.public_subnet_region}"
   map_public_ip_on_launch = true
   tags = {
    Name = "Public Subnet"
  }        
 }
                    
 resource "aws_subnet" "privatesubnets" {
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.private_subnets}"
   availability_zone = "${var.private_subnet_region}"
   tags = {
    Name = "Private Subnet"
  }                                           
 }

 resource "aws_internet_gateway" "IGW" {    
    vpc_id =  aws_vpc.Main.id
    tags = {
    Name = "IG-Public-&-Private-VPC"
  }               
 }

 resource "aws_route_table" "PublicRT" {   
    vpc_id =  aws_vpc.Main.id
         route {
    cidr_block = "0.0.0.0/0"               
    gateway_id = aws_internet_gateway.IGW.id
     }
 }

 
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.PublicRT.id
 }

 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = aws_subnet.privatesubnets.id
    route_table_id = aws_route_table.PrivateRT.id
 }
 resource "aws_eip" "nateIP" {
   vpc   = true
 }

 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.publicsubnets.id
 }

 resource "aws_route_table" "PrivateRT" {    
   vpc_id = aws_vpc.Main.id
   route {
   cidr_block = "0.0.0.0/0"             
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }
 }

 resource "aws_security_group" "taskmain" {
  name        = "taskmain"
  description = "security group"
  vpc_id      = aws_vpc.Main.id

   ingress {
    description      = "CUSTOM_TCP"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 }


 resource "aws_instance" "my_instance" {
  ami = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  key_name = "terraform"
  subnet_id = aws_subnet.publicsubnets.id
  security_groups = ["${aws_security_group.taskmain.id}"]
  user_data = "${file("docker.sh")}"
  tags = {
    Name = "public instance"
    }
  }

  resource "aws_instance" "my_instance2" {
  ami = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  key_name = "terraform"
  subnet_id = aws_subnet.privatesubnets.id
  security_groups = ["${aws_security_group.taskmain.id}"]
  user_data = "${file("docker.sh")}"
  tags = {
    Name = "private instance"
    }
  }
