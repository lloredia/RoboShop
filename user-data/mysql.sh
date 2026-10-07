#!/bin/bash
##############################################
# MariaDB for RoboShop shipping data
# Root stays on localhost. The shipping account
# is limited to the application subnet.
# Password-validation plugins are left enabled.
##############################################

set -euo pipefail

LOG_FILE="/var/log/roboshop-mysql-install.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "========================================="
echo "MariaDB installation started: $(date)"
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
: "${MYSQL_APP_HOST_PATTERN:?MYSQL_APP_HOST_PATTERN is required}"
: "${SHIPPING_SCHEMA_URL:?SHIPPING_SCHEMA_URL is required}"

case "${MYSQL_APP_HOST_PATTERN}" in
  *.%) ;;
  *)
    echo "MYSQL_APP_HOST_PATTERN must look like 10.0.10.% (got ${MYSQL_APP_HOST_PATTERN})" >&2
    exit 1
    ;;
esac

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

yum install -y awscli
amazon-linux-extras enable mariadb10.5
yum clean metadata
yum install -y mariadb-server

systemctl enable mariadb
systemctl start mariadb

root_password="$(fetch_ssm "${SSM_PREFIX}/mysql/root_password")"
app_user="$(fetch_ssm "${SSM_PREFIX}/mysql/app_user")"
app_password="$(fetch_ssm "${SSM_PREFIX}/mysql/app_password")"
app_host="${MYSQL_APP_HOST_PATTERN}"

install -d -m 0750 /etc/roboshop
umask 077
cat > /etc/roboshop/mysql-root.cnf <<EOF
[client]
user=root
password=${root_password}
protocol=socket
EOF
chmod 0600 /etc/roboshop/mysql-root.cnf

# First-boot root still authenticates through the local socket.
mysql --protocol=socket -uroot <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${root_password}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
FLUSH PRIVILEGES;
SQL

curl -fsSL "${SHIPPING_SCHEMA_URL}" -o /tmp/shipping.sql
# The upstream dump grants a wildcard account. Drop those statements.
grep -viE '^[[:space:]]*GRANT[[:space:]]' /tmp/shipping.sql > /tmp/shipping.filtered.sql
mysql --defaults-extra-file=/etc/roboshop/mysql-root.cnf < /tmp/shipping.filtered.sql
rm -f /tmp/shipping.sql /tmp/shipping.filtered.sql

mysql --defaults-extra-file=/etc/roboshop/mysql-root.cnf <<SQL
DROP USER IF EXISTS '${app_user}'@'%';
DROP USER IF EXISTS '${app_user}'@'localhost';
CREATE USER '${app_user}'@'${app_host}' IDENTIFIED BY '${app_password}';
GRANT SELECT, INSERT, UPDATE, DELETE ON cities.* TO '${app_user}'@'${app_host}';
FLUSH PRIVILEGES;
SQL

install -d -o mysql -g mysql -m 0750 /backup/mysql
cat > /usr/local/bin/mysql-backup.sh <<'EOF'
#!/bin/bash
set -euo pipefail
backup_dir="/backup/mysql"
stamp="$(date +%Y%m%d_%H%M%S)"
mysqldump --defaults-extra-file=/etc/roboshop/mysql-root.cnf --all-databases > "${backup_dir}/backup_${stamp}.sql"
gzip "${backup_dir}/backup_${stamp}.sql"
find "${backup_dir}" -name '*.sql.gz' -mtime +7 -delete
EOF
chmod 0750 /usr/local/bin/mysql-backup.sh

tmp_cron="$(mktemp)"
crontab -l 2>/dev/null | grep -v 'mysql-backup.sh' > "${tmp_cron}" || true
echo "0 2 * * * /usr/local/bin/mysql-backup.sh" >> "${tmp_cron}"
crontab "${tmp_cron}"
rm -f "${tmp_cron}"

unset root_password app_password
echo "MariaDB is up. Root is localhost-only. App host pattern: ${app_host}"
echo "MariaDB installation completed: $(date)"
