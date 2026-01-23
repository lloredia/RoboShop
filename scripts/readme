# ⚡ RoboShop EC2 Controller

> **Lightning-fast AWS EC2 instance management for your RoboShop infrastructure**

[![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?style=flat&logo=amazon-aws)](https://aws.amazon.com/ec2/)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🚀 Quick Start

```bash
# Start all RoboShop instances
./start-roboshop.sh

# Stop all RoboShop instances
./stop-roboshop.sh

# Dry run to preview changes
./start-roboshop.sh --dry-run
./stop-roboshop.sh --dry-run
```

## ✨ Features

- 🎯 **Tag-based filtering** - Target instances by Project tags
- 🔒 **Safe by default** - Confirmation prompts & dry-run mode
- 🌈 **Beautiful output** - Color-coded status & formatted tables
- ⚡ **Region support** - Works across any AWS region
- 🛡️ **Error handling** - Comprehensive validation & troubleshooting
- 📊 **Real-time status** - Live instance state tracking

## 📋 Prerequisites

- AWS CLI v2+ installed and configured
- Valid AWS credentials with EC2 permissions
- Bash 4.0+ (Git Bash on Windows supported)

## 🎮 Usage Examples

```bash
# Specific region
./start-roboshop.sh --region us-west-2

# Custom tags
./stop-roboshop.sh --tag-key Environment --tag-value Production

# Multi-region operations
for region in us-east-1 us-west-2 eu-west-1; do
    ./start-roboshop.sh --region $region
done
```

## 🛠️ Configuration

Default settings (customize via flags):

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--tag-key` | `Project` | AWS tag key to filter |
| `--tag-value` | `RoboShop` | AWS tag value to filter |
| `--region` | `us-east-1` | AWS region |
| `--dry-run` | `false` | Preview without execution |

## 📸 Screenshots

```
========================================
RoboShop EC2 Instance Starter
========================================
✓ Authenticated as: arn:aws:iam::123456789012:user/devops
✓ Account ID: 123456789012
✓ Region: us-east-1

INSTANCE ID          NAME                           STATE           PRIVATE IP      PUBLIC IP
--------------------------------------------------------------------------------
i-0abc123def456     roboshop-mongodb               stopped         10.0.1.10       -
i-0def456ghi789     roboshop-catalogue             stopped         10.0.2.20       -
i-0ghi789jkl012     roboshop-redis                 stopped         10.0.3.30       -

ℹ INFO: Total instances: 3
⚠ WARNING: Are you sure you want to start these instances? (yes/no):
```

## 🤝 Contributing

Built for the DevOps team by [lloredia](https://github.com/lloredia) | Contributions welcome!

## 📝 License

MIT License - feel free to use and modify for your infrastructure needs.

---

<div align="center">
  <strong>⭐ Star this repo if it saved you time!</strong>
</div>
