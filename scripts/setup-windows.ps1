param(
    [string]$Distro = 'PryOSBuilder',
    [string]$Location = (Join-Path $env:LOCALAPPDATA 'PryOS/wsl')
)
$ErrorActionPreference = 'Stop'
# A dedicated distribution keeps image customization separate from Docker and daily work.
$installed = ((& wsl.exe --list --quiet) -replace "`0", '') -split "`r?`n"
if ($installed.Trim() -notcontains $Distro) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Location) | Out-Null
    & wsl.exe --install -d Ubuntu-24.04 --name $Distro --location $Location --no-launch
    if ($LASTEXITCODE -ne 0) { throw 'WSL installation failed. Windows may require an elevated terminal or restart before retrying.' }
}
$project = Split-Path -Parent $PSScriptRoot
$linuxProject = (& wsl.exe -d $Distro -u root --exec wslpath -a $project).Trim()
& wsl.exe -d $Distro -u root --exec bash "$linuxProject/scripts/setup-linux.sh"
if ($LASTEXITCODE -ne 0) { throw 'Builder dependency installation failed.' }
