param([Parameter(Mandatory=$true)][string]$Fteqcc)
$ErrorActionPreference='Stop'
$compiler=(Resolve-Path -LiteralPath $Fteqcc).Path
Push-Location "$PSScriptRoot\game"
try {
    & $compiler -O2
    if($LASTEXITCODE -ne 0){throw 'AD VR gameplay compilation failed'}
} finally { Pop-Location }
