param([Parameter(Mandatory=$true)][string]$GameDirectory, [string]$Engine)
$ErrorActionPreference='Stop'
$destination=(Resolve-Path -LiteralPath $GameDirectory).Path
if(-not (Test-Path -LiteralPath "$destination\ad\pak0.pak")){throw 'Choose your QuakeVR directory containing the complete ad folder'}
$overlay=Join-Path $destination 'advr'
New-Item -ItemType Directory -Force -Path $overlay | Out-Null
Copy-Item -LiteralPath "$PSScriptRoot\advr-progs.dat" -Destination "$overlay\progs.dat"
Copy-Item -LiteralPath "$PSScriptRoot\runtime\advr_start.cfg" -Destination $overlay
Copy-Item -LiteralPath "$PSScriptRoot\runtime\default.cfg" -Destination $overlay
Copy-Item -LiteralPath "$PSScriptRoot\runtime\progs" -Destination $overlay -Recurse -Force
Copy-Item -LiteralPath "$PSScriptRoot\runtime\QuakeVR-AD.bat" -Destination $destination
Copy-Item -LiteralPath "$PSScriptRoot\runtime\QuakeVR-AD-Standard-Textures.bat" -Destination $destination

if($Engine){Copy-Item -LiteralPath (Resolve-Path -LiteralPath $Engine).Path -Destination "$destination\ironwail-ad.exe"}
