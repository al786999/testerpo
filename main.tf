# main.tf

provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}

resource "aws_instance" "example" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI ID for us-eas888t-1
  instance_type = "t3.micro"
subnet_id = "subnet-0707d40ddbb9d0818"


  tags = {
    Name = "example-instance"
  }
}

output "instance_id" {
  value = aws_instance.example.id
}

output "instance_public_ip" {
  value = aws_instance.example.public_ip
}
