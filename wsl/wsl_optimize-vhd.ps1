# WSL VHD Optimizer Script
# Version 2.0

# Note: You can run it via PowerShell ISE or PowerShell Console (or create a bat file for convenience).

function Normalize-WSLPath($path) {
    if ($null -eq $path) { return $null }
    $p = $path.Trim()
    if ($p.StartsWith("\\?\")) {
        return $p.Substring(4)
    }
    return $p
}

function Get-WSLDistros {
    $distroList = @()
    $lxssPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
    $entries = Get-ChildItem $lxssPath -ErrorAction SilentlyContinue

    foreach ($entry in $entries) {
        $props = Get-ItemProperty "$lxssPath\$($entry.PSChildName)"
        $name = $props.DistributionName.Trim()
        $basePath = Normalize-WSLPath $props.BasePath

        if ($name -and $basePath -and (Test-Path $basePath)) {
            $vhdPath = Join-Path $basePath "ext4.vhdx"
            if (Test-Path $vhdPath) {
                $distroList += [PSCustomObject]@{
                    Name = $name
                    VHD  = $vhdPath
                }
            } else {
                Write-Host "VHD not found for $name at $vhdPath"
            }
        } else {
            Write-Host "Skipping $name (BasePath=$basePath)"
        }
    }
    return $distroList
}

# --- MAIN ---

# Check Hyper-V module
if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
    Write-Error "`nThe Hyper-V module is not installed. Enable it via 'Turn Windows features on or off'."
    Read-Host -Prompt "`nPress Enter to exit"
    exit
}

Write-Host "`nDetecting WSL distributions..."
$distros = @(Get-WSLDistros)

# Selection
if ($distros.Count -gt 0) {
    Write-Host "`nFound the following WSL distributions:"
    for ($i = 0; $i -lt $distros.Count; $i++) {
        Write-Host "[$($i+1)] $($distros[$i].Name) - $($distros[$i].VHD)"
    }
    Write-Host "[M] Manual input"
    $choice = Read-Host "`nChoose a number or 'M' for manual input"

    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $distros.Count) {
        $distro = $distros[[int]$choice - 1].Name
        $vhdxPath = $distros[[int]$choice - 1].VHD
    } else {
        Write-Host "`nManual mode selected."
        $distro = Read-Host "`nEnter the name of your WSL distribution"
        $vhdxPath = Read-Host "`nEnter the full path to the .vhdx file"
    }
} else {
    Write-Host "`nNo distros detected automatically. Switching to manual mode."
    $distro = Read-Host "`nEnter the name of your WSL distribution"
    $vhdxPath = Read-Host "`nEnter the full path to the .vhdx file"
}

# --- VALIDATION ---

$distro = $distro.Trim()
$vhdxPath = $vhdxPath.Trim()

if ([string]::IsNullOrWhiteSpace($distro)) {
    Write-Error "Invalid distro name. Exiting."
    exit
}

$validDistros = wsl --list --quiet 2>$null
if ($validDistros -notcontains $distro) {
    Write-Error "The specified distro '$distro' does not exist."
    exit
}

if ([string]::IsNullOrWhiteSpace($vhdxPath)) {
    Write-Error "Invalid VHDX path. Exiting."
    exit
}
if (-not (Test-Path $vhdxPath)) {
    Write-Error "The specified VHDX file does not exist: $vhdxPath"
    exit
}

# --- ACTIONS ---

try {
    Write-Host "`nDisabling sparse for $distro..."
    wsl --manage $distro --set-sparse false

    Write-Host "`nOptimizing disk ($vhdxPath)..."
    Optimize-VHD -Path $vhdxPath -Mode Full -ErrorAction Stop

    Write-Host "`nEnabling sparse for $distro..."
    wsl --manage $distro --set-sparse true

    Write-Host "`nOperation completed successfully."
} catch {
    Write-Error "`nAn error occurred: $_"
}
