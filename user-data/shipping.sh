#!/bin/bash
##############################################
# Shipping service (Java). The upstream source
# hardcodes a lab database password; this script
# rewrites that to environment variables before
# the jar is built.
##############################################

set -euo pipefail

LOG_FILE="/var/log/roboshop-shipping-install.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "========================================="
echo "Shipping installation started: $(date)"
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
: "${SHIPPING_URL:?SHIPPING_URL is required}"

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

yum install -y awscli java-1.8.0-openjdk java-1.8.0-openjdk-devel maven unzip
id roboshop >/dev/null 2>&1 || useradd --system --create-home --home-dir /home/roboshop --shell /bin/bash roboshop
install -d -o roboshop -g roboshop -m 0755 /app

curl -fsSL "${SHIPPING_URL}" -o /tmp/shipping.zip
unzip -o /tmp/shipping.zip -d /app
rm -f /tmp/shipping.zip
chown -R roboshop:roboshop /app

jpa="/app/src/main/java/com/instana/robotshop/shipping/JpaConfig.java"
if [[ ! -f "${jpa}" ]]; then
  echo "shipping source did not contain ${jpa}" >&2
  exit 1
fi
sed -i 's/bob\.username("shipping");/bob.username(System.getenv("DB_USER"));/' "${jpa}"
sed -i 's/bob\.password("[^"]*");/bob.password(System.getenv("DB_PASS"));/' "${jpa}"
if grep -q 'RoboShop@1' "${jpa}"; then
  echo "refusing to compile the upstream lab database password into shipping" >&2
  exit 1
fi

sudo -u roboshop bash -lc 'cd /app && mvn -B -DskipTests package'
jar="$(find /app/target -type f -name 'shipping-*.jar' ! -name '*sources*' ! -name '*javadoc*' | head -n 1)"
if [[ -z "${jar}" ]]; then
  echo "maven did not produce a shipping jar" >&2
  exit 1
fi
install -o roboshop -g roboshop -m 0644 "${jar}" /app/shipping.jar

app_user="$(fetch_ssm "${SSM_PREFIX}/mysql/app_user")"
app_password="$(fetch_ssm "${SSM_PREFIX}/mysql/app_password")"
install -d -m 0750 /etc/roboshop
umask 077
cat > /etc/roboshop/shipping.env <<EOF
CART_ENDPOINT=cart.${PRIVATE_DOMAIN}:8080
DB_HOST=mysql.${PRIVATE_DOMAIN}
DB_USER=${app_user}
DB_PASS=${app_password}
EOF
chown root:root /etc/roboshop/shipping.env
chmod 0600 /etc/roboshop/shipping.env
unset app_password

cat > /etc/systemd/system/shipping.service <<'EOF'
[Unit]
Description=Shipping Service
After=network.target

[Service]
User=roboshop
WorkingDirectory=/app
EnvironmentFile=/etc/roboshop/shipping.env
ExecStart=/usr/bin/java -jar /app/shipping.jar
Restart=always
RestartSec=10
SyslogIdentifier=shipping

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable shipping
systemctl start shipping
echo "Shipping installation completed: $(date)"
