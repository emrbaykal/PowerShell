# Script to Install PowerShell Modules on a Disconnected Server

# Define the path where the modules are stored relative to the script location
$ModulePath = "$PSScriptRoot\PowerShell-Modules"

# List of modules to install
$Modules = @(
    "HPESimpliVity",
    "VMware.VimAutomation.Core",
    "Posh-SSH"
)

# Function to install a module from the local path
function Install-ModuleFromLocal {
    param (
        [string]$ModuleName,
        [string]$SourcePath
    )

    Write-Host "Installing module: $ModuleName from $SourcePath" -ForegroundColor Green

    # Check if the module is already installed
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Write-Host "$ModuleName is already installed." -ForegroundColor Yellow
    } else {
        # Install the module from the local source
        try {
            Import-Module -Name "$SourcePath\$ModuleName" -ErrorAction Stop
            Write-Host "$ModuleName installed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to install $ModuleName. Error: $_" -ForegroundColor Red
        }
    }
}

# Iterate through the modules and install them
foreach ($Module in $Modules) {
    $ModuleSourcePath = "$ModulePath\$Module"
    if (Test-Path $ModuleSourcePath) {
        Install-ModuleFromLocal -ModuleName $Module -SourcePath $ModuleSourcePath
    } else {
        Write-Host "Module path $ModuleSourcePath does not exist. Skipping $Module." -ForegroundColor Red
    }
}

# Verify the installation
Write-Host "Verifying installed modules..." -ForegroundColor Cyan
foreach ($Module in $Modules) {
    if (Get-Module -ListAvailable -Name $Module) {
        Write-Host "$Module is available." -ForegroundColor Green
    } else {
        Write-Host "$Module is not available. Please check the installation." -ForegroundColor Red
    }
}
