#!/usr/bin/env bash
#
# deploy.sh — sube web/index.html a la instancia EC2 con scp y verifica.
# Requiere que `terraform apply` ya se haya ejecutado en ../terraform.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TF_DIR="$ROOT_DIR/terraform"
KEY="$TF_DIR/lab1-key.pem"
PAGE="$ROOT_DIR/web/index.html"

IP="$(terraform -chdir="$TF_DIR" output -raw public_ip)"
echo ">> Instancia: $IP"

SSH_OPTS=(-i "$KEY" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5)

echo ">> Esperando a que SSH responda..."
for i in $(seq 1 30); do
  if ssh "${SSH_OPTS[@]}" -o BatchMode=yes "ec2-user@$IP" true 2>/dev/null; then
    echo ">> SSH listo."
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "!! SSH no respondió tras 5 min" >&2
    exit 1
  fi
  sleep 10
done

echo ">> Esperando a que termine cloud-init (instalación de nginx)..."
ssh "${SSH_OPTS[@]}" "ec2-user@$IP" 'sudo cloud-init status --wait' || true

echo ">> Verificando que nginx esté activo..."
for i in $(seq 1 18); do
  if ssh "${SSH_OPTS[@]}" "ec2-user@$IP" 'systemctl is-active --quiet nginx && test -d /usr/share/nginx/html'; then
    echo ">> nginx activo."
    break
  fi
  if [ "$i" -eq 18 ]; then
    echo "!! nginx no quedó activo tras 3 min" >&2
    exit 1
  fi
  sleep 10
done

echo ">> Subiendo index.html con scp..."
scp "${SSH_OPTS[@]}" "$PAGE" "ec2-user@$IP:/tmp/index.html"

echo ">> Instalando la página en el docroot de nginx..."
ssh "${SSH_OPTS[@]}" "ec2-user@$IP" \
  'sudo cp /tmp/index.html /usr/share/nginx/html/index.html && sudo systemctl reload nginx'

echo ">> Verificando con curl..."
for i in $(seq 1 12); do
  if curl -fsS "http://$IP" | grep -q "subió a la instancia usando"; then
    echo ">> OK: la página se está sirviendo correctamente."
    echo ">> URL: http://$IP"
    exit 0
  fi
  sleep 5
done

echo "!! No se pudo verificar la página vía HTTP" >&2
exit 1
