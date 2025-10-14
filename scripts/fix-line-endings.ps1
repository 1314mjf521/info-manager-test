# Fix Line Endings Script
# This script fixes Windows CRLF line endings in shell scripts

param(
    [string]$RemoteHost = "192.168.100.15",
    [string]$RemoteUser = "root",
    [string]$RemotePath = "/opt/info-management-system"
)

Write-Host "[INFO] Fixing line endings on remote server..." -ForegroundColor Blue

$fixScript = @'
#!/bin/bash
set -e

echo "Fixing line endings and permissions..."

cd /opt/info-management-system

# Install dos2unix if not available
if ! command -v dos2unix >/dev/null 2>&1; then
    echo "Installing dos2unix..."
    if command -v yum >/dev/null 2>&1; then
        yum install -y dos2unix
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y dos2unix
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y dos2unix
    else
        echo "Warning: Could not install dos2unix, trying manual conversion"
        # Manual conversion using sed
        find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
        find . -name "*.yml" -type f -exec sed -i 's/\r$//' {} \;
        find . -name "*.yaml" -type f -exec sed -i 's/\r$//' {} \;
    fi
fi

# Fix line endings for shell scripts
echo "Converting line endings..."
find . -name "*.sh" -type f -exec dos2unix {} \; 2>/dev/null || {
    echo "Using sed for line ending conversion..."
    find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
}

# Fix line endings for config files
find . -name "*.yml" -type f -exec dos2unix {} \; 2>/dev/null || find . -name "*.yml" -type f -exec sed -i 's/\r$//' {} \;
find . -name "*.yaml" -type f -exec dos2unix {} \; 2>/dev/null || find . -name "*.yaml" -type f -exec sed -i 's/\r$//' {} \;

# Set execute permissions
echo "Setting execute permissions..."
find . -name "*.sh" -type f -exec chmod +x {} \;

echo "Line endings and permissions fixed successfully"
'@

# Execute the fix script on remote server
$fixScript | & ssh "${RemoteUser}@${RemoteHost}" "cat > /tmp/fix-line-endings.sh && chmod +x /tmp/fix-line-endings.sh && /tmp/fix-line-endings.sh && rm /tmp/fix-line-endings.sh"

Write-Host "[SUCCESS] Line endings fixed on remote server" -ForegroundColor Green