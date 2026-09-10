# Lab1 DSE — EC2 + WebServer con Terraform

Práctica: lanzar una instancia **EC2** con **Terraform**, desplegar un **web server**
simple (nginx sobre Amazon Linux 2023), subir una **página HTML** a la instancia usando
**`scp`** y conectarse para verificar.

## Estructura

```
terraform/     Infraestructura como código (EC2, Security Group, key pair)
web/index.html Página estática que se sirve desde la instancia
scripts/deploy.sh  Sube web/index.html por scp y verifica con curl
```

## Requisitos

- Terraform >= 1.5
- AWS CLI configurado con credenciales válidas (perfil `default`).
  En AWS Academy Learner Lab: copiar el bloque `[default]` de *AWS Details* a
  `~/.aws/credentials`. **Las credenciales STS caducan en horas**; si Terraform
  devuelve `ExpiredToken`, vuelve a copiarlas.
- `ssh`, `scp` y `curl` en el PATH.

## Uso

### 1. Provisionar la infraestructura

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

Terraform:
- genera un par de llaves SSH y escribe la privada en `terraform/lab1-key.pem` (chmod 600),
- crea un Security Group con **22 (SSH)** y **80 (HTTP)** abiertos,
- lanza una instancia `t3.micro` con Amazon Linux 2023 en la VPC/subnet por defecto,
- instala y arranca **nginx** vía `user_data`.

Outputs relevantes: `public_ip`, `url`, `ssh_command`.

### 2. Subir la página con scp

Desde la raíz del repo:

```bash
bash scripts/deploy.sh
```

El script espera a que SSH responda, hace
`scp web/index.html ec2-user@<ip>:/tmp/`, la copia al docroot
(`/usr/share/nginx/html/index.html`), recarga nginx y verifica con `curl`.

### 3. Conectarse a la instancia

```bash
ssh -i terraform/lab1-key.pem ec2-user@<public_ip>
# o directamente:
$(cd terraform && terraform output -raw ssh_command)
```

Verificación rápida:

```bash
curl http://<public_ip>
ssh -i terraform/lab1-key.pem ec2-user@<public_ip> 'systemctl is-active nginx'
```

### 4. Destruir todo

```bash
cd terraform
terraform destroy -auto-approve
```

## Notas de seguridad

- El Security Group abre 22 y 80 a `0.0.0.0/0` por simplicidad de laboratorio.
  Para uso real, restringe `ssh_ingress_cidr` a tu IP.
- `terraform/lab1-key.pem` y el estado de Terraform están en `.gitignore` y **no** se versionan.
