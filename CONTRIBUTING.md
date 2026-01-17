# Contributing to RoboShop Infrastructure

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your feature
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Development Workflow

### For Infrastructure Changes (Terraform)
```bash
cd terraform
terraform fmt        # Format code
terraform validate   # Validate syntax
terraform plan      # Preview changes
```

### For Configuration Changes (Ansible)
```bash
cd ansible
ansible-playbook --syntax-check site.yml  # Check syntax
ansible-playbook --check site.yml         # Dry run
```

## Coding Standards

### Terraform
- Use meaningful resource names
- Add comments for complex logic
- Follow HashiCorp naming conventions
- Use modules for reusable components
- Always include `description` in variables

### Ansible
- Use descriptive task names
- Include `become` only when necessary
- Use handlers for service restarts
- Keep roles focused and single-purpose
- Use variables for configurable values

## Pull Request Process

1. Update README.md with details of changes
2. Update CHANGELOG.md with your changes
3. Ensure all tests pass
4. Request review from maintainers
5. Squash commits before merging

## Reporting Issues

When reporting issues, please include:
- Environment details (AWS region, Terraform version, etc.)
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs or error messages
- Screenshots if applicable

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Keep discussions professional

## Questions?

Feel free to open an issue for questions or discussions.
