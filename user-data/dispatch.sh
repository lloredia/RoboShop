#!/bin/bash
##############################################
# Dispatch service (Go). Consumes RabbitMQ.
# No inbound application port.
##############################################

set -euo pipefail

LOG_FILE="/var/log/roboshop-dispatch-install.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "========================================="
echo "Dispatch installation started: $(date)"
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
: "${DISPATCH_URL:?DISPATCH_URL is required}"

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

yum install -y awscli golang unzip git
id roboshop >/dev/null 2>&1 || useradd --system --create-home --home-dir /home/roboshop --shell /bin/bash roboshop
install -d -o roboshop -g roboshop -m 0755 /app

curl -fsSL "${DISPATCH_URL}" -o /tmp/dispatch.zip
unzip -o /tmp/dispatch.zip -d /app
rm -f /tmp/dispatch.zip
chown -R roboshop:roboshop /app

sudo -u roboshop bash -lc '
  set -euo pipefail
  cd /app
  export GO111MODULE=on
  export GOPROXY=https://proxy.golang.org,direct
  go mod init dispatch
  go get github.com/streadway/amqp@v1.0.0
  go get github.com/opentracing/opentracing-go@v1.2.0
  go build -o /app/dispatch .
'

app_user="$(fetch_ssm "${SSM_PREFIX}/rabbitmq/user")"
app_password="$(fetch_ssm "${SSM_PREFIX}/rabbitmq/password")"
install -d -m 0750 /etc/roboshop
umask 077
cat > /etc/roboshop/dispatch.env <<EOF
AMQP_HOST=rabbitmq.${PRIVATE_DOMAIN}
AMQP_USER=${app_user}
AMQP_PASS=${app_password}
EOF
chown root:root /etc/roboshop/dispatch.env
chmod 0600 /etc/roboshop/dispatch.env
unset app_password

cat > /etc/systemd/system/dispatch.service <<'EOF'
[Unit]
Description=Dispatch Service
After=network.target

[Service]
User=roboshop
WorkingDirectory=/app
EnvironmentFile=/etc/roboshop/dispatch.env
ExecStart=/app/dispatch
Restart=always
RestartSec=10
SyslogIdentifier=dispatch

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dispatch
systemctl start dispatch
echo "Dispatch installation completed: $(date)"
