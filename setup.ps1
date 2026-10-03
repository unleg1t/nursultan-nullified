<#
  Sets up the runtime for nursultan-nullified on Windows.

    .\setup.ps1            set up libraries only
    .\setup.ps1 -WithJdk   also download a JDK 17 into .\jre

  If PowerShell blocks the script, run:
    powershell -ExecutionPolicy Bypass -File .\setup.ps1
#>
param([switch]$WithJdk)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

$versionJson = 'https://piston-meta.mojang.com/v1/packages/fba9f7833e858a1257d810d21a3a9e3c967f9077/1.16.5.json'
$fastutil    = '8.5.13'
$jdkUrl      = 'https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse'

New-Item -ItemType Directory -Force -Path 'libraries\libs', 'libraries\natives' | Out-Null

function Get-File([string]$Url, [string]$Out) {
    if (Test-Path -LiteralPath $Out) { return }
    Write-Host "    $([IO.Path]::GetFileName($Out))"
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Out
}

Write-Host '==> Minecraft 1.16.5 libraries + Windows natives'
$spec = Invoke-RestMethod -UseBasicParsing -Uri $versionJson
foreach ($lib in $spec.libraries) {
    $allow = $true
    if ($lib.rules) {
        $allow = $false
        foreach ($r in $lib.rules) {
            if ($r.action -eq 'allow'    -and -not $r.os -or ($r.os.name -eq 'windows')) { $allow = $true }
            if ($r.action -eq 'disallow' -and $r.os.name -eq 'windows')                    { $allow = $false }
        }
    }
    if (-not $allow) { continue }

    $art = $lib.downloads.artifact
    if ($art.url) {
        Get-File $art.url (Join-Path 'libraries\libs' (Split-Path $art.path -Leaf))
    }
    $nat = $lib.downloads.classifiers.'natives-windows'
    if ($nat.url) {
        $tmp = Join-Path $env:TEMP ("nn_" + [IO.Path]::GetFileName($nat.path) + ".zip")
        Get-File $nat.url $tmp
        $ex = Join-Path $env:TEMP 'nn_natives'
        if (Test-Path $ex) { Remove-Item -Recurse -Force $ex }
        [IO.Compression.ZipFile]::ExtractToDirectory($tmp, $ex)
        Get-ChildItem -Path $ex -Filter *.dll -Recurse | ForEach-Object {
            Copy-Item $_.FullName 'libraries\natives' -Force
        }
        Remove-Item -Recurse -Force $ex, $tmp
    }
}

Write-Host '==> fastutil'
Get-File "https://repo1.maven.org/maven2/it/unimi/dsi/fastutil/$fastutil/fastutil-$fastutil.jar" "libraries\libs\fastutil-$fastutil.jar"
Remove-Item -Force 'libraries\libs\fastutil-8.2.1.jar' -ErrorAction SilentlyContinue

Write-Host '==> copying prebuilt client files'
Copy-Item 'prebuilt\libs\*.jar' 'libraries\libs' -Force
Copy-Item 'prebuilt\natives\*.dll' 'libraries\natives' -Force

if ($WithJdk) {
    Write-Host '==> downloading JDK 17 into .\jre'
    $zip = Join-Path $env:TEMP 'nursultan-jdk.zip'
    Invoke-WebRequest -UseBasicParsing -Uri $jdkUrl -OutFile $zip
    if (Test-Path 'jre') { Remove-Item -Recurse -Force 'jre' }
    $ex = Join-Path $env:TEMP 'nursultan-jdk'
    if (Test-Path $ex) { Remove-Item -Recurse -Force $ex }
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $ex)
    $root = Get-ChildItem $ex -Directory | Select-Object -First 1
    Move-Item $root.FullName 'jre'
    Remove-Item -Recurse -Force $ex, $zip
}

Write-Host ''
Write-Host 'Done. Launch with start.bat (Windows) or ./start.sh (Linux/Wine).'
