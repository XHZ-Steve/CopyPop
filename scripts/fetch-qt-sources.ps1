param([string]$Version='6.11.1',[string]$Destination)
$ErrorActionPreference='Stop'
if(-not $Destination){$Destination=Join-Path (Split-Path $PSScriptRoot -Parent) 'dist/CopyPop-1.0.0-third-party-sources'}
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
$series=($Version.Split('.')[0..1] -join '.')
$modules='qtbase','qtdeclarative','qtsvg','qtshadertools','qtimageformats'
foreach($module in $modules){
    $name="$module-everywhere-src-$Version.tar.xz"
    $file=Join-Path $Destination $name
    if(-not (Test-Path -LiteralPath $file)){
        Write-Host "Downloading corresponding source: $name"
        $temporary="$file.partial"
        Invoke-WebRequest -Uri "https://download.qt.io/official_releases/qt/$series/$Version/submodules/$name" -OutFile $temporary
        Move-Item -LiteralPath $temporary -Destination $file
    }
}
Get-FileHash -Path "$Destination/*.tar.xz" -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" } | Set-Content -LiteralPath "$Destination/SHA256SUMS.txt" -Encoding ascii
@"
Unmodified official Qt $Version corresponding sources for CopyPop's dynamic Qt dependencies.
Keep these files available alongside the binary distribution.
See the CopyPop THIRD_PARTY_NOTICES.md and each archive's LICENSES and build documentation.
Binary kit: official Windows x64 MinGW 13.1.0 Qt installer build. No Qt source modifications.
Upstream configure/build instructions: https://doc.qt.io/qt-6/windows-building.html
Qt is built with its own standard module CMake configure process; use a matching x64 compiler.
CopyPop itself can be rebuilt with scripts/build.ps1 and linked to a replacement compatible Qt kit.
"@ | Set-Content -LiteralPath "$Destination/README.txt" -Encoding utf8
