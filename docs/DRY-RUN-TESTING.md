# Comprehensive Dry Run Testing System

## Overview

The dotfiles repository now includes a comprehensive dry run testing system that allows you to preview exactly what changes would be made to your system without actually applying them. This system provides enterprise-grade testing capabilities with detailed reporting, conflict detection, and safety checks.

## Key Features

### ✅ **Complete System Preview**
- **File System Changes**: Preview all files, directories, and symlinks that would be created or modified
- **Package Installations**: See exactly which Homebrew formulae, casks, and Mac App Store apps would be installed
- **System Configuration**: Preview all macOS defaults and system settings changes
- **Service Management**: See which system services would be started, stopped, or modified

### ✅ **Advanced Safety Checks**
- **System State Capture**: Takes snapshots before and after operations to detect unexpected changes
- **Conflict Detection**: Identifies potential issues like low disk space, running processes, or permission problems
- **Hardware Compatibility**: Validates that profile requirements match your hardware capabilities
- **Dependency Validation**: Ensures all required tools and conditions are met

### ✅ **Comprehensive Reporting**
- **Structured JSON Reports**: Machine-readable change logs with detailed metadata
- **Visual Console Output**: Colour-coded preview with clear change categorisation
- **Change Tracking**: Counts and categorises all types of modifications
- **Rollback Information**: Details on how changes could be reversed

### ✅ **Enterprise Testing Framework**
- **BATS Test Suite**: Automated test validation using industry-standard testing tools
- **Module Isolation**: Tests each component independently to isolate issues
- **Profile Validation**: Tests all setup profiles (developer, data-scientist, personal, minimal)
- **Performance Monitoring**: Tracks execution time and resource usage

## Quick Start

### Basic Dry Run
```bash
# Preview changes for developer profile
./scripts/00-bootstrap.zsh --dry-run --profile developer

# Preview specific modules only
./scripts/00-bootstrap.zsh --dry-run --modules-only "01,03,05"

# Preview with detailed output
./scripts/00-bootstrap.zsh --dry-run --profile data-scientist --verbose
```

### Module-Specific Testing
```bash
# Test individual modules
./scripts/03-homebrew-setup.zsh --dry-run --profile developer
./scripts/05-macos-defaults.zsh --dry-run
./scripts/08-development-env.zsh --dry-run --profile data-scientist
```

### Comprehensive Validation
```bash
# Run full validation suite
./scripts/validate-dry-run.zsh

# Quick validation
./scripts/validate-dry-run.zsh --quick

# Test specific module
./scripts/validate-dry-run.zsh --module homebrew-setup
```

## How It Works

### 1. **Dry Run Utilities Library**
Located at `scripts/lib/dry-run-utils.zsh`, this library provides standardised functions for:

```bash
# Command execution without side effects
dr_execute "Install packages" brew install git jq
dr_sudo "Configure system" defaults write com.apple.dock tilesize 48

# File system operations preview
dr_mkdir "Create config directory" "$HOME/.config/app"
dr_symlink "Link dotfiles" "$DOTFILES_ROOT/zsh/dot-zshrc" "$HOME/.zshrc"
dr_write_file "Create config" "$HOME/.app/config.json" "$config_content"

# Package management simulation
dr_brew_install "Install development tools" git node python
dr_brew_bundle "Install from Brewfile" "$DOTFILES_ROOT/config/Brewfile.developer"

# System configuration preview
dr_defaults_write "Set dock size" "com.apple.dock" "tilesize" "int" "48"
dr_service "Start service" "start" "com.example.daemon"
```

### 2. **System State Monitoring**
The system captures comprehensive state information:

```json
{
  "timestamp": "2025-01-07T10:30:00Z",
  "system_info": {
    "macos_version": "13.0",
    "hardware_model": "MacBookPro18,1",
    "hostname": "MacBook-Pro"
  },
  "disk_space": {
    "available_gb": 250,
    "used_gb": 250
  },
  "homebrew": {
    "installed": true,
    "formula_count": 85,
    "cask_count": 23
  },
  "shell_environment": {
    "shell": "/bin/zsh",
    "zsh_version": "5.8",
    "path_entries": ["$HOMEBREW_PREFIX/bin", "/usr/local/bin", "/usr/bin"]
  }
}
```

### 3. **Change Detection and Reporting**
All changes are tracked and categorised:

```json
{
  "modules": {
    "homebrew-setup": {
      "started": "2025-01-07T10:30:00Z",
      "changes": [
        {
          "type": "package",
          "description": "Install development tools",
          "details": {
            "packages": ["git", "node", "python"],
            "already_installed": ["git"],
            "would_install": ["node", "python"]
          }
        }
      ],
      "completed": "2025-01-07T10:32:15Z"
    }
  },
  "summary": {
    "total_changes": 15,
    "file_changes": 8,
    "package_installs": 4,
    "service_changes": 2,
    "defaults_changes": 1
  }
}
```

## Advanced Usage

### Testing Specific Scenarios

#### Hardware-Specific Testing
```bash
# Test Mac Studio configuration
./scripts/00-bootstrap.zsh --dry-run --profile developer
# Automatically detects hardware and shows relevant packages

# Test different hardware profiles
HARDWARE_TYPE="studio" ./scripts/06-applications.zsh --dry-run
HARDWARE_TYPE="macbook" ./scripts/06-applications.zsh --dry-run
```

#### Profile Comparison
```bash
# Compare what different profiles would install
./scripts/00-bootstrap.zsh --dry-run --profile minimal > minimal-preview.txt
./scripts/00-bootstrap.zsh --dry-run --profile developer > developer-preview.txt
diff minimal-preview.txt developer-preview.txt
```

#### Incremental Testing
```bash
# Test specific modules in sequence
for module in 01 02 03 04 05; do
  echo "Testing module $module..."
  ./scripts/$(ls scripts/${module}-*.zsh) --dry-run
done
```

### Custom Validation Scripts

Create your own validation scripts using the dry run utilities:

```bash
#!/usr/bin/env zsh
source scripts/lib/dry-run-utils.zsh

# Set up dry run mode
export DRY_RUN_ENABLED=true
dr_init "custom_test"

# Test your operations
dr_execute "Custom operation" my_command arg1 arg2
dr_mkdir "Custom directory" "/tmp/test"

# Generate report
dr_finalize_module "custom_test"
dr_generate_summary
```

## Testing Framework

### BATS Integration
Run automated tests to verify dry run functionality:

```bash
# Install BATS if not available
brew install bats-core

# Run the test suite
bats tests/test_dry_run.bats

# Run specific test categories
bats tests/test_dry_run.bats --filter "command execution"
bats tests/test_dry_run.bats --filter "file operations"
```

### Test Categories

#### 1. **Core Functionality Tests**
- Dry run initialization and reporting
- Command execution simulation
- State capture and comparison
- JSON report generation

#### 2. **File System Tests**
- Directory creation simulation
- Symlink management preview
- File writing without actual changes
- Permission and ownership handling

#### 3. **Package Management Tests**
- Homebrew formula simulation
- Cask installation preview
- Mac App Store app detection
- Brewfile parsing and analysis

#### 4. **System Configuration Tests**
- macOS defaults preview
- Service management simulation
- Security settings validation
- Hardware-specific configurations

#### 5. **Integration Tests**
- Full profile installations
- Module interaction testing
- Cross-system validation
- Performance benchmarking

### Continuous Validation

Set up automated validation in your workflow:

```bash
#!/bin/bash
# .github/workflows/validate-dry-run.yml equivalent

echo "Running dry run validation..."
./scripts/validate-dry-run.zsh --quick

if [ $? -eq 0 ]; then
  echo "✅ Dry run validation passed"
else
  echo "❌ Dry run validation failed"
  exit 1
fi
```

## Troubleshooting

### Common Issues

#### 1. **Missing Dependencies**
```bash
# Check required tools
command -v jq || brew install jq
command -v bats || brew install bats-core

# Verify dry run utilities are loaded
source scripts/lib/dry-run-utils.zsh
dr_is_enabled && echo "Dry run enabled" || echo "Dry run disabled"
```

#### 2. **Permission Issues**
```bash
# Ensure test directories are writable
mkdir -p ~/.config/dotfiles-setup
chmod 755 ~/.config/dotfiles-setup

# Check file permissions
ls -la scripts/lib/dry-run-utils.zsh
chmod +x scripts/validate-dry-run.zsh
```

#### 3. **State Comparison Failures**
```bash
# Clear any stale state files
rm -rf ~/.config/dotfiles-setup/system-state-*.json

# Run with verbose output to debug
./scripts/validate-dry-run.zsh --verbose
```

### Debug Mode

Enable detailed debugging:

```bash
# Set debug environment
export DEBUG=true
export VERBOSE=true
export DRY_RUN_ENABLED=true

# Run with maximum detail
./scripts/00-bootstrap.zsh --dry-run --debug --verbose
```

## Report Analysis

### Reading JSON Reports

Use jq to analyse detailed reports:

```bash
# View summary
jq '.summary' ~/.config/dotfiles-setup/dry-run-report.json

# List all changes by type
jq '.modules[].changes[] | select(.type == "package")' report.json

# Count changes by module
jq -r '.modules | to_entries[] | "\(.key): \(.value.changes | length) changes"' report.json

# Find potential conflicts
jq '.modules[].changes[] | select(.description | contains("conflict"))' report.json
```

### Performance Analysis

Monitor resource usage during dry runs:

```bash
# Time dry run execution
time ./scripts/00-bootstrap.zsh --dry-run --profile developer

# Monitor memory usage
/usr/bin/time -l ./scripts/validate-dry-run.zsh --quick

# Profile script execution
zmodload zsh/zprof
./scripts/03-homebrew-setup.zsh --dry-run
zprof
```

## Best Practices

### 1. **Always Test Before Applying**
```bash
# Good: Test first, then apply
./scripts/00-bootstrap.zsh --dry-run --profile developer
./scripts/00-bootstrap.zsh --profile developer

# Better: Compare multiple scenarios
./scripts/00-bootstrap.zsh --dry-run --profile developer > dev.txt
./scripts/00-bootstrap.zsh --dry-run --profile data-scientist > ds.txt
diff dev.txt ds.txt
```

### 2. **Use Version Control for Reports**
```bash
# Save reports for comparison
mkdir -p reports/$(date +%Y-%m-%d)
./scripts/validate-dry-run.zsh > "reports/$(date +%Y-%m-%d)/validation.txt"

# Track changes over time
git add reports/
git commit -m "Add dry run validation report for $(date +%Y-%m-%d)"
```

### 3. **Validate on Different Systems**
- Test on clean macOS installations
- Validate across different hardware types (MacBook, Mac Studio, Mac Mini)
- Test with different existing software configurations
- Verify behaviour with various macOS versions

### 4. **Monitor System Resources**
- Check available disk space before large installations
- Monitor memory usage during package installations
- Validate network connectivity for remote packages
- Ensure sufficient permissions for system modifications

## Contributing

### Adding Dry Run Support to New Modules

1. **Source the utilities library**:
```bash
source "${SCRIPT_DIR}/lib/dry-run-utils.zsh"
dr_set_module "my-module"
```

2. **Initialize dry run mode**:
```bash
if [[ $DRY_RUN == true ]]; then
    export DRY_RUN_ENABLED=true
    dr_init "my-module"
fi
```

3. **Replace system commands**:
```bash
# Instead of: mkdir -p "$dir"
dr_mkdir "Create directory" "$dir"

# Instead of: defaults write com.app key value
dr_defaults_write "Set app preference" "com.app" "key" "string" "value"

# Instead of: brew install package
dr_brew_install "Install package" package
```

4. **Finalize reporting**:
```bash
if [[ $DRY_RUN == true ]]; then
    dr_finalize_module "my-module"
    dr_generate_summary
fi
```

### Adding New Tests

1. **Create test functions** in `tests/test_dry_run.bats`:
```bash
@test "my new feature works correctly" {
    export DRY_RUN_ENABLED=true
    source lib/dry-run-utils.zsh
    
    run my_test_function
    [ "$status" -eq 0 ]
    [ -f "$DRY_RUN_REPORT_FILE" ]
}
```

2. **Add validation scenarios** to `scripts/validate-dry-run.zsh`:
```bash
test_my_feature() {
    # Test implementation
    return 0
}

# Add to main test execution
run_test "My Feature" test_my_feature
```

## Future Enhancements

### Planned Features
- **Web-based report viewer** for complex installations
- **Interactive dry run mode** with step-by-step confirmation
- **Rollback script generation** for automated cleanup
- **Integration with CI/CD pipelines** for automated testing
- **Performance benchmarking** and optimisation recommendations
- **Cloud integration** for sharing and comparing configurations

### Experimental Features
- **Docker-based testing** for completely isolated environments
- **Virtual machine integration** for testing on fresh systems
- **Configuration drift detection** for ongoing system monitoring
- **Automated conflict resolution** suggestions

---

## Support

For issues, questions, or contributions:

1. **Check existing documentation** in this repository
2. **Run validation tests** to identify specific problems
3. **Submit issues** with detailed dry run reports
4. **Contribute improvements** following the coding standards

**Co-Authored-By**: Claude <noreply@anthropic.com>