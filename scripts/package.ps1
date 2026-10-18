param([string]$QtRoot = $env:QT_ROOT,[switch]$Installer)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
& "$PSScriptRoot/build.ps1" -Configuration release -QtRoot $QtRoot
$cache=Get-Content -LiteralPath "$projectRoot/build/release/CMakeCache.txt"
$qtConfig=($cache | Select-String '^Qt6_DIR:PATH=(.*)$').Matches[0].Groups[1].Value
$kitRoot=(Resolve-Path -LiteralPath "$qtConfig/../../..").Path
$env:PATH="$kitRoot/bin;$env:PATH"
$stage=Join-Path $projectRoot 'dist/CopyPop-1.0.0-windows-x64'
if(Test-Path -LiteralPath $stage){
    $resolved=(Resolve-Path -LiteralPath $stage).Path
    $expected=[IO.Path]::GetFullPath((Join-Path $projectRoot 'dist/CopyPop-1.0.0-windows-x64'))
    if($resolved -ne $expected -or ((Get-Item -LiteralPath $stage).Attributes -band [IO.FileAttributes]::ReparsePoint)){ throw 'Unsafe staging directory; refusing to clean.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $stage | Out-Null
& cmake --install "$projectRoot/build/release" --prefix $stage
if($LASTEXITCODE){throw 'Install failed'}
& "$kitRoot/bin/windeployqt.exe" --release --verbose 0 --compiler-runtime --no-translations --no-opengl-sw --no-system-d3d-compiler --skip-plugin-types generic,platforminputcontexts,qmltooling,vectorimageformats,networkinformation,tls --qmldir "$projectRoot/qml" --dir $stage "$stage/CopyPop.exe"
if($LASTEXITCODE){throw 'windeployqt failed'}
Copy-Item -LiteralPath "$projectRoot/docs" -Destination $stage -Recurse -Force
Copy-Item -LiteralPath "$projectRoot/examples" -Destination $stage -Recurse -Force
# Qt ships module license manifests; retain the manifests for audit alongside our notices.
if(Test-Path -LiteralPath "$kitRoot/sbom") {
    New-Item -ItemType Directory -Force -Path "$stage/licenses/qt-sbom" | Out-Null
    foreach($module in 'qtbase','qtdeclarative','qtsvg','qtshadertools','qtimageformats') {
        Get-ChildItem -LiteralPath "$kitRoot/sbom" -Filter "$module-*" | Copy-Item -Destination "$stage/licenses/qt-sbom" -Force
    }
}
$qtVersion=& "$kitRoot/bin/qmake.exe" -query QT_VERSION
if($LASTEXITCODE){throw 'Unable to determine exact Qt source version.'}
& "$PSScriptRoot/fetch-qt-sources.ps1" -Version $qtVersion
$archive=Join-Path $projectRoot 'dist/CopyPop-1.0.0-windows-x64.zip'
Compress-Archive -Path "$stage/*" -DestinationPath $archive -Force
Get-FileHash -LiteralPath $archive -Algorithm SHA256 | Format-List
if($Installer){
    $env:CPACK_INSTALLED_DIRECTORIES="$stage;."
    & cpack --config "$projectRoot/build/release/CPackConfig.cmake" -G NSIS -B "$projectRoot/dist" -D "CPACK_INSTALLED_DIRECTORIES=$stage;." -D 'CPACK_INSTALL_CMAKE_PROJECTS='
    if($LASTEXITCODE){throw 'NSIS packaging failed. Install NSIS and put makensis in PATH.'}
}
Get-FileHash -LiteralPath $archive,"$stage/CopyPop.exe" -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $([IO.Path]::GetRelativePath((Join-Path $projectRoot 'dist'),$_.Path))" } | Set-Content -LiteralPath "$projectRoot/dist/SHA256SUMS.txt" -Encoding ascii
if($Installer){Get-FileHash -LiteralPath "$projectRoot/dist/CopyPop-1.0.0-win64.exe" -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" } | Add-Content -LiteralPath "$projectRoot/dist/SHA256SUMS.txt" -Encoding ascii}
