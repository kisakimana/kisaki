# Get server and key
param($server, $key, $tls)

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "Require PS >= 5, your PSVersion:" $PSVersionTable.PSVersion.Major -BackgroundColor DarkGreen -ForegroundColor White
    Write-Host "Refer to the community article and install manually! https://nyko.me/2020/12/13/nezha-windows-client.html" -BackgroundColor DarkRed -ForegroundColor Green
    exit
}

# Set agent repo and fixed version
$agentrepo = "nezhahq/agent"
$agenttag = "v0.20.5"

# Determine file type based on architecture
if ([System.Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        $file = "nezha-agent_windows_arm64.zip"
    } else {
        $file = "nezha-agent_windows_amd64.zip"
    }
} else {
    $file = "nezha-agent_windows_386.zip"
}

# Remove existing installation if present
if (Test-Path "C:\nezha\nezha-agent.exe") {
    Write-Host "Nezha monitoring already exists, delete and reinstall" -BackgroundColor DarkGreen -ForegroundColor White
    # Stop the nezha-agent process
    if (Get-Process -Name "nezha-agent" -ErrorAction SilentlyContinue) {
        Stop-Process -Name "nezha-agent" -Force
    }
    C:\nezha\nezha-agent.exe service uninstall
    Remove-Item "C:\nezha" -Recurse -Force
}

# Determine download URL
$region = "Unknown"
foreach ($url in ("https://dash.cloudflare.com/cdn-cgi/trace", "https://developers.cloudflare.com/cdn-cgi/trace", "https://1.0.0.1/cdn-cgi/trace")) {
    try {
        $ipapi = Invoke-RestMethod -Uri $url -TimeoutSec 5 -UseBasicParsing
        if ($ipapi -match "loc=(\w+)") {
            $region = $Matches[1]
            break
        }
    } catch {
        Write-Host "Error occurred while querying $url : $_"
    }
}

if ($region -ne "CN") {
    $download = "https://github.com/$agentrepo/releases/download/$agenttag/$file"
    Write-Host "Location: $region, connect directly!" -BackgroundColor DarkRed -ForegroundColor Green
} else {
    $download = "https://gitee.com/naibahq/agent/releases/download/$agenttag/$file"
    Write-Host "Location: CN, use mirror address" -BackgroundColor DarkRed -ForegroundColor Green
}

# Download and extract files
Write-Host "Downloading Nezha Agent from $download" -BackgroundColor DarkGreen -ForegroundColor White
Invoke-WebRequest $download -OutFile "C:\nezha.zip"
Expand-Archive "C:\nezha.zip" -DestinationPath "C:\temp" -Force

# Create installation directory
if (!(Test-Path "C:\nezha")) { New-Item -Path "C:\nezha" -Type Directory }

# Move files to installation directory
if (Test-Path "C:\nezha\nezha-agent.exe") {
    Remove-Item "C:\nezha\nezha-agent.exe" -Force
}
Move-Item -Path "C:\temp\nezha-agent.exe" -Destination "C:\nezha\nezha-agent.exe"

# Clean up temporary files
Remove-Item "C:\nezha.zip"
Remove-Item "C:\temp" -Recurse

# Install service
C:\nezha\nezha-agent.exe service install -s "$server" -p "$key" $tls

# Done
Write-Host "Enjoy It!" -BackgroundColor DarkGreen -ForegroundColor Red
