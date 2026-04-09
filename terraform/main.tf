provider "aws" {
  region = "eu-north-1"
}

# Dynamically fetch the latest Ubuntu 24.04 image
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Create a Security Group (Firewall) for the Target Node
resource "aws_security_group" "target_sg" {
  name        = "target_server_sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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
}

# Create the Target EC2 Instance
resource "aws_instance" "target_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  
  # IMPORTANT: Change this to the exact name of your existing key pair (without the .pem extension)
  key_name               = "myKey" 
  
  vpc_security_group_ids = [aws_security_group.target_sg.id]

  # This script runs automatically on startup to install Docker on the Target Node
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install docker.io -y
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "Target-Node"
  }
}

# Output the IP address of the new server so Jenkins knows where to deploy
output "target_public_ip" {
  value = aws_instance.target_server.public_ip
}