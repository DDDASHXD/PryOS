param(
    [string]$Distro = 'PryOSBuilder',
    [string]$WorkDir = '/var/tmp/pryos-build',
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$linuxProject = (& wsl.exe -d $Distro --exec wslpath -a $project).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Install the Ubuntu WSL2 builder using scripts/setup-windows.ps1 first.' }
& wsl.exe -d $Distro -u root --exec env "PRYOS_WORK_DIR=$WorkDir" "PRYOS_FORCE=$([int]$Force.IsPresent)" bash "$linuxProject/build-iso.sh"
if ($LASTEXITCODE -ne 0) { throw 'PryOS build failed; inspect out/build.log.' }
