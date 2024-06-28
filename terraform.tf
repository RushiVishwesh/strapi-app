provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "terra_key_strapi" {
  key_name   = "terra_key_strapi"
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_security_group" "strapi_terra_sg_vishwesh" {
  name        = "strapi_terra_sg_vishwesh"
  description = "strapi_terra_sg_vishwesh"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom Port"
    from_port   = 1337
    to_port     = 1337
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
    Name = "strapi_terra_sg_vishwesh"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.terra_key_strapi.key_name
  security_groups = [aws_security_group.strapi_terra_sg_vishwesh.name]
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.example.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install nodejs npm -y",
      "sudo npm install -g yarn pm2",
      "git clone https://github.com/RushiVishwesh/strapi.git",
      "pm2 start \"yes 'skip' | yarn create strapi-app my-strapi-project --quickstart\" --name strapi-app",
      "echo \"application started successfully to ec2\""
    ]
  }

  tags = {
    Name = "StrapiTerraformInstance"
  }
}

output "private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}

output "instance_ip" {
  value = aws_instance.web.public_ip
}
