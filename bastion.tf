data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

resource "aws_instance" "bastion" {

  subnet_id            = [for subnet in aws_subnet.public: subnet.id][0]
  instance_type        = local.bastion_instance_type
  ami                  = data.aws_ami.bastion.id
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.bastion.id ]
  user_data = "echo GatewayPorts yes|sudo tee -a /etc/ssh/sshd_config"

  tags = {
    Name = "bastion"
  }
}

resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.vpc.id
  name = "bastion-sg"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 5432
    to_port = 5432
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