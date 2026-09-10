output "instance_id" {
  description = "ID de la instancia EC2."
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "IP pública de la instancia."
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "DNS público de la instancia."
  value       = aws_instance.web.public_dns
}

output "ssh_command" {
  description = "Comando para conectarse por SSH."
  value       = "ssh -i terraform/lab1-key.pem ec2-user@${aws_instance.web.public_ip}"
}

output "url" {
  description = "URL del web server."
  value       = "http://${aws_instance.web.public_ip}"
}
