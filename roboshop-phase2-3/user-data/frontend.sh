#!/bin/bash

##############################################
# Frontend (Nginx) Installation for RoboShop
# OS: Amazon Linux 2 / RHEL 8
##############################################

set -e

LOG_FILE="/var/log/roboshop-frontend-install.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "========================================="
echo "Frontend Installation Started: $(date)"
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

# Install Nginx
print_status "Installing Nginx..."
yum install -y nginx
check_status "Nginx installation"

# Enable and start Nginx
print_status "Starting Nginx service..."
systemctl enable nginx
systemctl start nginx
check_status "Nginx service start"

# Download frontend code
FRONTEND_URL=${FRONTEND_URL:-"https://roboshop-artifacts.s3.amazonaws.com/frontend.zip"}

print_status "Downloading frontend code..."
cd /usr/share/nginx/html
rm -rf *
curl -L -o /tmp/frontend.zip $FRONTEND_URL
check_status "Frontend code download"

# Extract frontend code
print_status "Extracting frontend code..."
unzip -o /tmp/frontend.zip
mv frontend-main/* . 2>/dev/null || mv frontend/* . 2>/dev/null || true
rm -rf frontend-main frontend /tmp/frontend.zip
check_status "Frontend code extraction"

# Configure Nginx for RoboShop
print_status "Configuring Nginx..."
cat > /etc/nginx/default.d/roboshop.conf <<'EOF'
proxy_http_version 1.1;
location /images/ {
  expires 5s;
  root   /usr/share/nginx/html;
  try_files $uri /images/placeholder.jpg;
}
location /api/catalogue/ { 
  proxy_pass http://catalogue.roboshop.internal:8080/; 
}
location /api/user/ { 
  proxy_pass http://user.roboshop.internal:8080/; 
}
location /api/cart/ { 
  proxy_pass http://cart.roboshop.internal:8080/; 
}
location /api/shipping/ { 
  proxy_pass http://shipping.roboshop.internal:8080/; 
}
location /api/payment/ { 
  proxy_pass http://payment.roboshop.internal:8080/; 
}
location /health {
  stub_status on;
  access_log off;
}
EOF
check_status "Nginx configuration"

# Restart Nginx
print_status "Restarting Nginx..."
systemctl restart nginx
check_status "Nginx restart"

# Configure firewall
if systemctl is-active --quiet firewalld; then
    print_status "Configuring firewall..."
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    check_status "Firewall configuration"
fi

# Test Nginx
print_status "Testing Nginx..."
curl -s http://localhost/health > /dev/null
check_status "Nginx health check"

# Print info
print_status "Frontend installation completed!"
echo "========================================="
echo "Nginx Version: $(nginx -v 2>&1)"
echo "Nginx Status: $(systemctl is-active nginx)"
echo "Document Root: /usr/share/nginx/html"
echo "Config: /etc/nginx/default.d/roboshop.conf"
echo "Logs: /var/log/nginx/"
echo ""
echo "Frontend URL: http://$(hostname -I | awk '{print $1}')"
echo "Health Check: http://$(hostname -I | awk '{print $1}')/health"
echo "========================================="

print_status "Installation log saved to: $LOG_FILE"

echo "========================================="
echo "Frontend Installation Completed: $(date)"
echo "========================================="
