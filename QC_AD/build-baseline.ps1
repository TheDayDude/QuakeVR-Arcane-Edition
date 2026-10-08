param([string]$Fteqcc)
$ErrorActionPreference='Stop'
if(-not $Fteqcc){throw 'Pass -Fteqcc with the path to fteqcc64.exe'}
$compiler=(Resolve-Path -LiteralPath $Fteqcc).Path
Push-Location "$PSScriptRoot\upstream"
try {
    & $compiler -O2
    if($LASTEXITCODE -ne 0){throw 'AD baseline compilation failed'}
} finally { Pop-Location }
