#!/bin/bash
##############################################
# Payment service (Python / uWSGI)
# AMQP credentials come from SSM. guest is not used.
##############################################

set -euo pipefail

LOG_FILE="/var/log/roboshop-payment-install.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "========================================="
echo "Payment installation started: $(date)"
echo "========================================="

if [[ -f /etc/roboshop/bootstrap.env ]]; then
  # shellcheck disable=SC1091
  set -a
  # shellcheck disable=SC1091
  . /etc/roboshop/bootstrap.env
  set +a
fi

: "${SSM_PREFIX:?SSM_PREFIX is required}"
: "${AWS_DEFAULT_REGION:?AWS_DEFAULT_REGION is required}"
: "${PRIVATE_DOMAIN:?PRIVATE_DOMAIN is required}"
: "${PAYMENT_URL:?PAYMENT_URL is required}"

fetch_ssm() {
  local name="$1"
  local value
  value="$(aws ssm get-parameter \
    --name "${name}" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --region "${AWS_DEFAULT_REGION}")"
  if [[ -z "${value}" || "${value}" == "None" ]]; then
    echo "Failed to read SSM parameter ${name}" >&2
    exit 1
  fi
  printf '%s' "${value}"
}

yum install -y awscli python3 python3-pip python3-devel gcc unzip
id roboshop >/dev/null 2>&1 || useradd --system --create-home --home-dir /home/roboshop --shell /bin/bash roboshop
install -d -o roboshop -g roboshop -m 0755 /app

curl -fsSL "${PAYMENT_URL}" -o /tmp/payment.zip
unzip -o /tmp/payment.zip -d /app
rm -f /tmp/payment.zip
sed -i 's/^uid = .*/uid = roboshop/' /app/payment.ini
sed -i 's/^gid = .*/gid = roboshop/' /app/payment.ini
chown -R roboshop:roboshop /app

python3 -m pip install --upgrade pip
python3 -m pip install -r /app/requirements.txt

app_user="$(fetch_ssm "${SSM_PREFIX}/rabbitmq/user")"
app_password="$(fetch_ssm "${SSM_PREFIX}/rabbitmq/password")"
install -d -m 0750 /etc/roboshop
umask 077
cat > /etc/roboshop/payment.env <<EOF
CART_HOST=cart.${PRIVATE_DOMAIN}
CART_PORT=8080
USER_HOST=user.${PRIVATE_DOMAIN}
USER_PORT=8080
AMQP_HOST=rabbitmq.${PRIVATE_DOMAIN}
AMQP_USER=${app_user}
AMQP_PASS=${app_password}
EOF
chown root:root /etc/roboshop/payment.env
chmod 0600 /etc/roboshop/payment.env
unset app_password

# uWSGI starts as root so payment.ini can drop to the roboshop user.
cat > /etc/systemd/system/payment.service <<'EOF'
[Unit]
Description=Payment Service
After=network.target

[Service]
WorkingDirectory=/app
EnvironmentFile=/etc/roboshop/payment.env
ExecStart=/usr/local/bin/uwsgi --ini /app/payment.ini
Restart=always
RestartSec=10
SyslogIdentifier=payment

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable payment
systemctl start payment
echo "Payment installation completed: $(date)"
