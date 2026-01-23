#!/usr/bin/env bash
#
# start-roboshop.sh - Safely start EC2 instances by tag
# Author: DevOps Team
# Usage: ./start-roboshop.sh [--region REGION] [--tag-key KEY] [--tag-value VALUE] [--dry-run]

set -euo pipefail

# ============================================================================
# Configuration & Defaults
# ============================================================================
DEFAULT_TAG_KEY="Project"
DEFAULT_TAG_VALUE="RoboShop"
DEFAULT_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"

TAG_KEY="${DEFAULT_TAG_KEY}"
TAG_VALUE="${DEFAULT_TAG_VALUE}"
REGION="${DEFAULT_REGION}"
DRY_RUN=false

# ============================================================================
# Color codes for output (works in Git Bash)
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ INFO: $1${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Start EC2 instances matching specified tags.

OPTIONS:
    --region REGION          AWS region (default: ${DEFAULT_REGION})
    --tag-key KEY           Tag key to filter (default: ${DEFAULT_TAG_KEY})
    --tag-value VALUE       Tag value to filter (default: ${DEFAULT_TAG_VALUE})
    --dry-run               Show what would happen without starting
    --help                  Show this help message

EXAMPLES:
    # Start all RoboShop instances in default region
    ./start-roboshop.sh

    # Start instances in specific region
    ./start-roboshop.sh --region us-west-2

    # Start instances with custom tag
    ./start-roboshop.sh --tag-key Environment --tag-value Production

    # Dry run to see what would be started
    ./start-roboshop.sh --dry-run

EOF
    exit 0
}

# ============================================================================
# Validate AWS CLI Authentication
# ============================================================================
validate_aws_auth() {
    print_info "Validating AWS credentials..."
    
    if ! aws sts get-caller-identity --region "${REGION}" &>/dev/null; then
        print_error "AWS authentication failed!"
        echo ""
        echo "Troubleshooting steps:"
        echo "1. Run: aws configure"
        echo "2. Verify credentials: aws sts get-caller-identity"
        echo "3. Check AWS_PROFILE environment variable"
        echo "4. Ensure your credentials are not expired"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --region "${REGION}" --query 'Account' --output text)
    USER_ARN=$(aws sts get-caller-identity --region "${REGION}" --query 'Arn' --output text)
    
    print_success "Authenticated as: ${USER_ARN}"
    print_success "Account ID: ${ACCOUNT_ID}"
    print_success "Region: ${REGION}"
}

# ============================================================================
# Get and Display EC2 Instances
# ============================================================================
get_instances() {
    local filter_tag="Name=tag:${TAG_KEY},Values=${TAG_VALUE}"
    local filter_state="Name=instance-state-name,Values=stopped"
    
    print_info "Querying instances with tag ${TAG_KEY}=${TAG_VALUE} in state 'stopped'..."
    
    # Query AWS for instances
    INSTANCES=$(aws ec2 describe-instances \
        --region "${REGION}" \
        --filters "${filter_tag}" "${filter_state}" \
        --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PrivateIpAddress,PublicIpAddress]' \
        --output text)
    
    if [[ -z "${INSTANCES}" ]]; then
        print_warning "No stopped instances found with tag ${TAG_KEY}=${TAG_VALUE}"
        return 1
    fi
    
    return 0
}

# ============================================================================
# Display Instances Table
# ============================================================================
display_instances() {
    print_header "Instances to be started"
    
    printf "%-20s %-30s %-15s %-15s %-15s\n" "INSTANCE ID" "NAME" "STATE" "PRIVATE IP" "PUBLIC IP"
    printf "%s\n" "--------------------------------------------------------------------------------"
    
    echo "${INSTANCES}" | while IFS=$'\t' read -r instance_id name state private_ip public_ip; do
        # Handle None/null values from AWS CLI
        [[ "${name}" == "None" ]] && name="-"
        [[ "${private_ip}" == "None" ]] && private_ip="-"
        [[ "${public_ip}" == "None" ]] && public_ip="-"
        
        printf "%-20s %-30s %-15s %-15s %-15s\n" \
            "${instance_id}" "${name}" "${state}" "${private_ip}" "${public_ip}"
    done
    
    echo ""
    INSTANCE_COUNT=$(echo "${INSTANCES}" | wc -l)
    print_info "Total instances: ${INSTANCE_COUNT}"
}

# ============================================================================
# Confirm Action
# ============================================================================
confirm_action() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        print_warning "DRY RUN MODE - No instances will be started"
        return 0
    fi
    
    echo ""
    echo -ne "${YELLOW}Are you sure you want to start these instances? (yes/no): ${NC}"
    read -r response
    
    if [[ "${response}" != "yes" ]]; then
        print_warning "Operation cancelled by user"
        exit 0
    fi
}

# ============================================================================
# Start Instances
# ============================================================================
start_instances() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        print_success "DRY RUN: Would start ${INSTANCE_COUNT} instance(s)"
        return 0
    fi
    
    print_header "Starting instances"
    
    # Extract instance IDs
    INSTANCE_IDS=$(echo "${INSTANCES}" | awk '{print $1}')
    
    print_info "Starting instances..."
    
    if aws ec2 start-instances \
        --region "${REGION}" \
        --instance-ids ${INSTANCE_IDS} \
        --output json > /dev/null 2>&1; then
        
        print_success "Start command sent successfully"
        echo ""
        print_info "Waiting for instances to start (this may take 1-2 minutes)..."
        
        # Wait for instances to be running
        if aws ec2 wait instance-running \
            --region "${REGION}" \
            --instance-ids ${INSTANCE_IDS} 2>/dev/null; then
            
            print_success "All instances started successfully!"
            
            # Show updated instance info
            echo ""
            print_header "Instance Status After Start"
            
            UPDATED_INSTANCES=$(aws ec2 describe-instances \
                --region "${REGION}" \
                --instance-ids ${INSTANCE_IDS} \
                --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PrivateIpAddress,PublicIpAddress]' \
                --output text)
            
            printf "%-20s %-30s %-15s %-15s %-15s\n" "INSTANCE ID" "NAME" "STATE" "PRIVATE IP" "PUBLIC IP"
            printf "%s\n" "--------------------------------------------------------------------------------"
            
            echo "${UPDATED_INSTANCES}" | while IFS=$'\t' read -r instance_id name state private_ip public_ip; do
                [[ "${name}" == "None" ]] && name="-"
                [[ "${private_ip}" == "None" ]] && private_ip="-"
                [[ "${public_ip}" == "None" ]] && public_ip="-"
                
                printf "%-20s %-30s %-15s %-15s %-15s\n" \
                    "${instance_id}" "${name}" "${state}" "${private_ip}" "${public_ip}"
            done
            
        else
            print_warning "Wait timeout - instances may still be starting"
            print_info "Check status with: aws ec2 describe-instances --instance-ids ${INSTANCE_IDS}"
        fi
    else
        print_error "Failed to start instances"
        exit 1
    fi
}

# ============================================================================
# Parse Arguments
# ============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --region)
                REGION="$2"
                shift 2
                ;;
            --tag-key)
                TAG_KEY="$2"
                shift 2
                ;;
            --tag-value)
                TAG_VALUE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                usage
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# ============================================================================
# Main Execution
# ============================================================================
main() {
    parse_args "$@"
    
    print_header "RoboShop EC2 Instance Starter"
    
    validate_aws_auth
    
    echo ""
    
    if get_instances; then
        display_instances
        confirm_action
        start_instances
        
        echo ""
        print_success "Operation completed successfully!"
    else
        exit 0
    fi
}

# Run main function
main "$@"