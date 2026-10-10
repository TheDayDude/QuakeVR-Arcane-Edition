param(
    [Parameter(Mandatory=$true)][string]$LlvmBin,
    [string]$VisualStudioRoot,
    [string]$MsvcVersion,
    [string]$WindowsSdkRoot='C:\Program Files (x86)\Windows Kits\10',
    [string]$WindowsSdkVersion,
    [string]$BuildDirectory
)
$ErrorActionPreference='Stop'
$sourceRoot=Split-Path $PSScriptRoot -Parent
$llvm=(Resolve-Path -LiteralPath $LlvmBin).Path
if(-not $VisualStudioRoot) {
    $vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if(-not (Test-Path -LiteralPath $vswhere)){throw 'Install Visual Studio C++ build tools, or supply -VisualStudioRoot'}
    $VisualStudioRoot=(& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1)
    if(-not $VisualStudioRoot){throw 'No Visual Studio C++ toolchain found'}
}
if(-not $MsvcVersion) {
    $MsvcVersion=(Get-ChildItem -LiteralPath "$VisualStudioRoot\VC\Tools\MSVC" -Directory | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1).Name
}
if(-not $WindowsSdkVersion) {
    $WindowsSdkVersion=(Get-ChildItem -LiteralPath "$WindowsSdkRoot\Include" -Directory | Where-Object {Test-Path -LiteralPath (Join-Path $_.FullName 'um\Windows.h')} | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1).Name
}
if(-not $MsvcVersion -or -not $WindowsSdkVersion){throw 'MSVC headers/libraries and a Windows SDK are required'}
if(-not $BuildDirectory){$BuildDirectory=Join-Path $sourceRoot 'build/windows'}
$BuildDirectory=[System.IO.Path]::GetFullPath($BuildDirectory)
$vc="$VisualStudioRoot\VC\Tools\MSVC\$MsvcVersion"
$sdk=$WindowsSdkRoot
$cmakeBase="$VisualStudioRoot\Common7\IDE\CommonExtensions\Microsoft\CMake"
$cmake="$cmakeBase\CMake\bin\cmake.exe"
if(-not (Test-Path -LiteralPath $cmake)){$cmake=(Get-Command cmake -ErrorAction Stop).Source}
$priorPath=$env:PATH; $priorInclude=$env:INCLUDE; $priorLib=$env:LIB
try {
    $env:PATH="$llvm;$vc\bin\Hostx64\x64;$sdk\bin\$WindowsSdkVersion\x64;$cmakeBase\Ninja;"+$priorPath
    $env:INCLUDE="$vc\include;$sdk\Include\$WindowsSdkVersion\ucrt;$sdk\Include\$WindowsSdkVersion\shared;$sdk\Include\$WindowsSdkVersion\um;$sdk\Include\$WindowsSdkVersion\winrt"
    $env:LIB="$vc\lib\x64;$sdk\Lib\$WindowsSdkVersion\ucrt\x64;$sdk\Lib\$WindowsSdkVersion\um\x64"
    & $cmake -S $sourceRoot -B $BuildDirectory -G Ninja -DCMAKE_BUILD_TYPE=Release '-DCMAKE_CL_SHOWINCLUDES_PREFIX=Note: including file: ' -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl
    if($LASTEXITCODE -ne 0){throw 'Engine configuration failed'}
    & $cmake --build $BuildDirectory --parallel 8
    if($LASTEXITCODE -ne 0){throw 'Engine build failed'}
} finally {
    $env:PATH=$priorPath; $env:INCLUDE=$priorInclude; $env:LIB=$priorLib
}
