variable "region" {
  description = "Región de AWS donde se despliega la práctica."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instancia EC2."
  type        = string
  default     = "t3.micro"
}

variable "project_name" {
  description = "Nombre del proyecto, usado para etiquetar recursos."
  type        = string
  default     = "lab1dse"
}

variable "ssh_ingress_cidr" {
  description = "CIDR autorizado para SSH (22). 0.0.0.0/0 sólo es aceptable en un lab."
  type        = string
  default     = "0.0.0.0/0"
}
