#!/bin/bash

##############################################
# MySQL Installation Script for RoboShop
# OS: Amazon Linux 2 / RHEL 8
##############################################

set -e

LOG_FILE="/var/log/roboshop-mysql-install.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "========================================="
echo "MySQL Installation Started: $(date)"
echo "========================================="

print_status() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_status() {
    if [ $? -eq 0 ]; then
        print_status "✓ SUCCESS: $1"
    else
        print_status "✗ FAILED: $1"
        exit 1
    fi
}

# Disable MySQL 8 module (for clean install)
print_status "Disabling default MySQL module..."
yum module disable mysql -y
check_status "MySQL module disable"

# Add MySQL 5.7 repository
print_status "Adding MySQL 5.7 repository..."
cat > /etc/yum.repos.d/mysql.repo <<EOF
[mysql57-community]
name=MySQL 5.7 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/7/x86_64/
enabled=1
gpgcheck=0
EOF
check_status "MySQL repository added"

# Install MySQL
print_status "Installing MySQL 5.7..."
yum install -y mysql-community-server
check_status "MySQL installation"

# Start MySQL service
print_status "Starting MySQL service..."
systemctl enable mysqld
systemctl start mysqld
check_status "MySQL service start"

# Get temporary root password
print_status "Retrieving temporary root password..."
TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
print_status "Temporary password retrieved"

# Set root password (using environment variable or default)
ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-RoboShop@1}

print_status "Setting root password..."
mysql --connect-expired-password -uroot -p"$TEMP_PASSWORD" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
check_status "Root password set"

# Configure MySQL for remote access
print_status "Configuring MySQL for remote access..."
mysql -uroot -p"$ROOT_PASSWORD" <<EOF
UNINSTALL PLUGIN validate_password;
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '$ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
check_status "Remote access configuration"

# Load shipping schema (if provided)
if [ -n "$SHIPPING_SCHEMA_URL" ]; then
    print_status "Loading shipping schema..."
    curl -s $SHIPPING_SCHEMA_URL -o /tmp/shipping.sql
    mysql -uroot -p"$ROOT_PASSWORD" < /tmp/shipping.sql
    check_status "Shipping schema load"
fi

# Configure firewall
if systemctl is-active --quiet firewalld; then
    print_status "Configuring firewall..."
    firewall-cmd --permanent --add-port=3306/tcp
    firewall-cmd --reload
    check_status "Firewall configuration"
fi

# Create backup directory
print_status "Creating backup directory..."
mkdir -p /backup/mysql
chown mysql:mysql /backup/mysql
check_status "Backup directory creation"

# Install backup script
print_status "Installing backup script..."
cat > /usr/local/bin/mysql-backup.sh <<BACKUP_SCRIPT
#!/bin/bash
BACKUP_DIR="/backup/mysql"
DATE=\$(date +%Y%m%d_%H%M%S)
mysqldump -uroot -p$ROOT_PASSWORD --all-databases > \$BACKUP_DIR/backup_\$DATE.sql
gzip \$BACKUP_DIR/backup_\$DATE.sql
find \$BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
BACKUP_SCRIPT

chmod +x /usr/local/bin/mysql-backup.sh
check_status "Backup script installation"

# Setup daily backup
print_status "Setting up daily backup..."
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/mysql-backup.sh") | crontab -
check_status "Cron job setup"

# Optimize MySQL configuration
print_status "Optimizing MySQL configuration..."
cat >> /etc/my.cnf <<EOF

# RoboShop optimizations
max_connections = 500
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
EOF
check_status "MySQL optimization"

# Restart MySQL to apply changes
print_status "Restarting MySQL..."
systemctl restart mysqld
check_status "MySQL restart"

# Print MySQL info
print_status "MySQL installation completed!"
echo "========================================="
echo "MySQL Version: $(mysql --version)"
echo "MySQL Status: $(systemctl is-active mysqld)"
echo "MySQL Port: 3306"
echo "Root Password: $ROOT_PASSWORD"
echo "MySQL Data Dir: /var/lib/mysql"
echo "MySQL Log: /var/log/mysqld.log"
echo "========================================="

print_status "Installation log saved to: $LOG_FILE"

echo "========================================="
echo "MySQL Installation Completed: $(date)"
echo "========================================="
