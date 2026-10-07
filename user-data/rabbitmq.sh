#!/bin/bash
##############################################
# RabbitMQ for RoboShop
# The default guest account is removed.
# The application user is not a cluster administrator.
##############################################

set -euo pipefail

LOG_FILE="/var/log/roboshop-rabbitmq-install.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "========================================="
echo "RabbitMQ installation started: $(date)"
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

yum install -y awscli curl
curl -fsSL https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash
yum install -y erlang
curl -fsSL https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash
yum install -y rabbitmq-server

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
sleep 10

rabbitmq-plugins enable rabbitmq_management
systemctl restart rabbitmq-server
sleep 10

app_user="$(fetch_ssm "${SSM_PREFIX}/rabbitmq/user")"
app_password="$(fetch_ssm "${SSM_PREFIX}/rabbitmq/password")"

if rabbitmqctl list_users | awk '{print $1}' | grep -qx 'guest'; then
  rabbitmqctl delete_user guest
fi

rabbitmqctl add_user "${app_user}" "${app_password}"
# management can open the UI from the bastion. It cannot administer the cluster.
rabbitmqctl set_user_tags "${app_user}" management
rabbitmqctl set_permissions -p / "${app_user}" ".*" ".*" ".*"

install -d -m 0755 /etc/rabbitmq
cat > /etc/rabbitmq/rabbitmq.conf <<'EOF'
listeners.tcp.default = 5672
management.tcp.port = 15672
management.tcp.ip = 0.0.0.0
vm_memory_high_watermark.relative = 0.6
disk_free_limit.absolute = 2GB
EOF

systemctl restart rabbitmq-server
sleep 10

install -d -m 0750 /etc/roboshop
umask 077
cat > /etc/roboshop/rabbitmq.netrc <<EOF
machine localhost
login ${app_user}
password ${app_password}
EOF
chmod 0600 /etc/roboshop/rabbitmq.netrc

install -d -m 0750 /backup/rabbitmq
cat > /usr/local/bin/rabbitmq-backup.sh <<'EOF'
#!/bin/bash
set -euo pipefail
backup_dir="/backup/rabbitmq"
stamp="$(date +%Y%m%d_%H%M%S)"
curl --netrc-file /etc/roboshop/rabbitmq.netrc \
  -fsS "http://localhost:15672/api/definitions" \
  -o "${backup_dir}/definitions_${stamp}.json"
find "${backup_dir}" -name 'definitions_*.json' -mtime +1 -exec gzip {} \;
find "${backup_dir}" -name 'definitions_*.json.gz' -mtime +7 -delete
EOF
chmod 0750 /usr/local/bin/rabbitmq-backup.sh

tmp_cron="$(mktemp)"
crontab -l 2>/dev/null | grep -v 'rabbitmq-backup.sh' > "${tmp_cron}" || true
echo "0 2 * * * /usr/local/bin/rabbitmq-backup.sh" >> "${tmp_cron}"
crontab "${tmp_cron}"
rm -f "${tmp_cron}"

unset app_password
echo "RabbitMQ user ${app_user} is ready. The guest account is not present."
echo "RabbitMQ installation completed: $(date)"
