param(
    [Parameter(Mandatory=$true)][string]$LlvmBin,
    [string]$VisualStudioRoot='C:\Program Files\Microsoft Visual Studio\2022\Community',
    [string]$MsvcVersion='14.37.32822',
    [string]$WindowsSdkRoot='C:\Program Files (x86)\Windows Kits\10',
    [string]$WindowsSdkVersion='10.0.22621.0'
)
$ErrorActionPreference='Stop' 
$sourceRoot=Split-Path $PSScriptRoot -Parent
$llvm=(Resolve-Path -LiteralPath $LlvmBin).Path
$vc="$VisualStudioRoot\VC\Tools\MSVC\$MsvcVersion"
$sdk=$WindowsSdkRoot
$cmakeBase="$VisualStudioRoot\Common7\IDE\CommonExtensions\Microsoft\CMake"
$env:PATH="$llvm;$vc\bin\Hostx64\x64;$sdk\bin\$WindowsSdkVersion\x64;$cmakeBase\Ninja;"+$env:PATH
$env:INCLUDE="$vc\include;$sdk\Include\$WindowsSdkVersion\ucrt;$sdk\Include\$WindowsSdkVersion\shared;$sdk\Include\$WindowsSdkVersion\um;$sdk\Include\$WindowsSdkVersion\winrt"
$env:LIB="$vc\lib\x64;$sdk\Lib\$WindowsSdkVersion\ucrt\x64;$sdk\Lib\$WindowsSdkVersion\um\x64"
& "$cmakeBase\CMake\bin\cmake.exe" -S "$sourceRoot" -B "$sourceRoot\build-ad" -G Ninja -DCMAKE_BUILD_TYPE=Release "-DCMAKE_CL_SHOWINCLUDES_PREFIX=Note: including file: " "-DCURL_DLL=$sourceRoot\Windows\curl\lib\x64\libcurl.dll" -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl
if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
& "$cmakeBase\CMake\bin\cmake.exe" --build "$sourceRoot\build-ad" --parallel 8
exit $LASTEXITCODE



