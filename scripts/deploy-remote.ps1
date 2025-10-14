# Remote Deployment Script - Final Fixed Version
param(
    [string]$RemoteHost = "192.168.100.15",
    [string]$RemoteUser = "root",
    [string]$RemotePath = "/opt/info-management-system"
)

Write-Host "[INFO] Remote Deployment Starting..." -ForegroundColor Blue
Write-Host "[INFO] Target: ${RemoteUser}@${RemoteHost}" -ForegroundColor Blue
Write-Host ""

# Test SSH connection
Write-Host "[INFO] Step 1/5: Testing SSH connection..." -ForegroundColor Blue
$sshTest = & ssh -o ConnectTimeout=10 "${RemoteUser}@${RemoteHost}" "echo OK"
if ($sshTest -ne "OK") {
    Write-Host "[ERROR] SSH connection failed" -ForegroundColor Red
    exit 1
}
Write-Host "[SUCCESS] SSH connection verified" -ForegroundColor Green

# Create directory
Write-Host "[INFO] Step 2/5: Creating application directory..." -ForegroundColor Blue
& ssh "${RemoteUser}@${RemoteHost}" "mkdir -p ${RemotePath}"

# Upload files
Write-Host "[INFO] Step 3/5: Uploading project files..." -ForegroundColor Blue
$excludeList = @('.git', 'build', 'logs', 'test', '.kiro', 'node_modules')
$tarArgs = $excludeList | ForEach-Object { "--exclude=$_" }
& tar -czf project.tar.gz $tarArgs .
& scp project.tar.gz "${RemoteUser}@${RemoteHost}:/tmp/"
& ssh "${RemoteUser}@${RemoteHost}" "cd ${RemotePath} && tar -xzf /tmp/project.tar.gz && rm /tmp/project.tar.gz"
Remove-Item project.tar.gz -ErrorAction SilentlyContinue
Write-Host "[SUCCESS] Files uploaded successfully" -ForegroundColor Green

# Install Docker - using individual commands instead of here-string
Write-Host "[INFO] Step 4/5: Installing Docker..." -ForegroundColor Blue

# Check if Docker exists
$dockerExists = & ssh "${RemoteUser}@${RemoteHost}" "command -v docker >/dev/null 2>&1 && echo 'exists' || echo 'missing'"
if ($dockerExists -eq "exists") {
    Write-Host "[INFO] Docker is already installed" -ForegroundColor Blue
} else {
    Write-Host "[INFO] Installing Docker..." -ForegroundColor Blue
    
    # Download Docker install script
    & ssh "${RemoteUser}@${RemoteHost}" "curl -fsSL https://get.docker.com -o /tmp/get-docker.sh"
    
    # Install Docker
    & ssh "${RemoteUser}@${RemoteHost}" "chmod +x /tmp/get-docker.sh && sh /tmp/get-docker.sh"
    
    # Start Docker service
    & ssh "${RemoteUser}@${RemoteHost}" "systemctl start docker && systemctl enable docker"
    
    # Install Docker Compose
    & ssh "${RemoteUser}@${RemoteHost}" "curl -L 'https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64' -o /usr/local/bin/docker-compose"
    & ssh "${RemoteUser}@${RemoteHost}" "chmod +x /usr/local/bin/docker-compose"
    
    # Clean up
    & ssh "${RemoteUser}@${RemoteHost}" "rm -f /tmp/get-docker.sh"
    
    Write-Host "[SUCCESS] Docker installed successfully" -ForegroundColor Green
}

# Verify Docker installation
& ssh "${RemoteUser}@${RemoteHost}" "docker --version && docker-compose --version"

# Deploy application - using individual commands
Write-Host "[INFO] Step 5/5: Deploying application..." -ForegroundColor Blue

# Fix line endings and permissions
& ssh "${RemoteUser}@${RemoteHost}" "cd ${RemotePath} && find . -name '*.sh' -type f -exec dos2unix {} \; 2>/dev/null || find . -name '*.sh' -type f -exec sed -i 's/\r$//' {} \;"
& ssh "${RemoteUser}@${RemoteHost}" "cd ${RemotePath} && find . -name '*.sh' -type f -exec chmod +x {} \;"

# Configure application
$configExists = & ssh "${RemoteUser}@${RemoteHost}" "cd ${RemotePath} && test -f configs/config.prod.yaml && echo 'exists' || echo 'missing'"
if ($configExists -eq "exists") {
    & ssh "${RemoteUser}@${RemoteHost}" "cd ${RemotePath} && cp configs/config.prod.yaml configs/config.yaml"
    Write-Host "[INFO] Using production configuration" -ForegroundColor Blue
} else {
    Write-Host "[INFO] Production config not found, using default" -ForegroundColor Yellow
}

# Stop existing services
& ssh "${RemoteUser}@${RemoteHost}" "cd ${RemotePath} && docker-compose down 2>/dev/null || true"

# Start services
& ssh "${RemoteUser}@${RemoteHost}" "cd ${RemotePath} && docker-compose up -d"

Write-Host "[SUCCESS] Application deployed!" -ForegroundColor Green

# Show service information
Write-Host ""
Write-Host "Service URLs:" -ForegroundColor Yellow
Write-Host "  Application: http://${RemoteHost}:8080" -ForegroundColor Cyan
Write-Host "  Health Check: http://${RemoteHost}:8080/health" -ForegroundColor Cyan
Write-Host "  API Documentation: http://${RemoteHost}:8080/api/v1" -ForegroundColor Cyan
Write-Host "  Grafana Monitoring: http://${RemoteHost}:3000 (admin/admin123)" -ForegroundColor Cyan
Write-Host "  Prometheus Metrics: http://${RemoteHost}:9090" -ForegroundColor Cyan
Write-Host ""

# Test deployment
Write-Host "[INFO] Testing deployment..." -ForegroundColor Blue
Start-Sleep -Seconds 20

$healthCheck = & ssh "${RemoteUser}@${RemoteHost}" "curl -s -f http://localhost:8080/health 2>/dev/null || echo 'failed'"
if ($healthCheck -ne "failed" -and $healthCheck) {
    Write-Host "[SUCCESS] Application is running and healthy!" -ForegroundColor Green
    Write-Host "Response: $healthCheck" -ForegroundColor Gray
} else {
    Write-Host "[WARNING] Health check failed - services may still be starting" -ForegroundColor Yellow
    Write-Host "[INFO] Check status: ssh ${RemoteUser}@${RemoteHost} 'cd ${RemotePath} && docker-compose ps'" -ForegroundColor Blue
}

Write-Host ""
Write-Host "Management Commands:" -ForegroundColor Yellow
Write-Host "  Status: ssh ${RemoteUser}@${RemoteHost} 'cd ${RemotePath} && docker-compose ps'" -ForegroundColor White
Write-Host "  Logs: ssh ${RemoteUser}@${RemoteHost} 'cd ${RemotePath} && docker-compose logs'" -ForegroundColor White
Write-Host "  Restart: ssh ${RemoteUser}@${RemoteHost} 'cd ${RemotePath} && docker-compose restart'" -ForegroundColor White
Write-Host "  Stop: ssh ${RemoteUser}@${RemoteHost} 'cd ${RemotePath} && docker-compose down'" -ForegroundColor White
Write-Host ""