########################################
# Par de llaves SSH (generado por Terraform)
########################################
resource "tls_private_key" "lab" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.lab.public_key_openssh
}

# La llave privada se escribe local para poder usar scp/ssh. No se versiona (.gitignore).
resource "local_file" "private_key" {
  content         = tls_private_key.lab.private_key_pem
  filename        = "${path.module}/lab1-key.pem"
  file_permission = "0600"
}

########################################
# Red: VPC y subnet por defecto
########################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################################
# AMI: Amazon Linux 2023 x86_64 (última, vía SSM)
########################################
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

########################################
# Security Group: SSH (22) + HTTP (80)
########################################
resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg"
  description = "Lab1 DSE: permite SSH y HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida a todo"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

########################################
# Instancia EC2 + web server (nginx)
########################################
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.lab.key_name
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  # user_data sólo instala y arranca el web server.
  # La página real se sube después con scp (scripts/deploy.sh).
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf install -y nginx
    systemctl enable --now nginx
    echo "<h1>${var.project_name}: servidor listo, esperando pagina...</h1>" > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name = var.project_name
  }
}
