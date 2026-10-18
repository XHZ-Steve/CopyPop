param(
    [ValidateSet('release','debug')][string]$Configuration = 'release',
    [string]$QtRoot = $env:QT_ROOT,
    [switch]$SkipTests
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not $QtRoot) {
    $candidates = @('D:/programs/Qt','C:/Qt','D:/Qt','E:/Qt')
    $kits = foreach ($base in $candidates) {
        if (Test-Path -LiteralPath $base) { Get-ChildItem -LiteralPath $base -Directory | Where-Object Name -Match '^6\.' | ForEach-Object {
            Get-ChildItem -LiteralPath $_.FullName -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'lib/cmake/Qt6/Qt6Config.cmake') }
        } }
    }
    $kit = $kits | Sort-Object { [version](Split-Path (Split-Path $_.FullName -Parent) -Leaf) } -Descending | Select-Object -First 1
    if (-not $kit) { throw 'No Qt 6 kit found. Set QT_ROOT to a kit such as C:/Qt/6.11.1/mingw_64.' }
    $QtRoot = $kit.FullName
}
$QtRoot = (Resolve-Path -LiteralPath $QtRoot).Path
$qtHome = Split-Path (Split-Path $QtRoot -Parent) -Parent
$kitName = Split-Path $QtRoot -Leaf
$env:PATH = "$QtRoot/bin;$qtHome/Tools/Ninja;$env:PATH"
$extra = @()
if ($kitName -match 'mingw') {
    $toolchain = Get-ChildItem -LiteralPath "$qtHome/Tools" -Directory -Filter 'mingw*_64' | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $toolchain) { throw 'Matching Qt MinGW compiler not found in Qt/Tools. Do not use an unrelated MSYS2 compiler.' }
    # Prefer the compiler used to build this kit, recorded by Qt when available.
    $recorded = Select-String -Path "$QtRoot/mkspecs/qconfig.pri" -Pattern '^QT_GCC_MAJOR_VERSION\s*=\s*(\d+)' -ErrorAction SilentlyContinue
    $compiler = Join-Path $toolchain.FullName 'bin/g++.exe'
    $version = & $compiler -dumpfullversion
    if ($recorded -and -not $version.StartsWith($recorded.Matches[0].Groups[1].Value+'.')) { throw "Qt compiler major mismatch: $version" }
    $env:PATH = "$($toolchain.FullName)/bin;$env:PATH"
    $extra = @("-DCMAKE_CXX_COMPILER=$compiler")
} elseif ($kitName -match 'msvc') {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $vs = & $vswhere -latest -property installationPath
    if (-not $vs) { throw 'MSVC Qt kit requires Visual Studio C++ build tools.' }
    $devcmd = Join-Path $vs 'Common7/Tools/VsDevCmd.bat'
    $lines = & cmd /c "`"$devcmd`" -arch=x64 >nul && set"
    foreach ($line in $lines) { if ($line -match '^([^=]+)=(.*)$') { [Environment]::SetEnvironmentVariable($matches[1],$matches[2],'Process') } }
    $extra = @('-DCMAKE_CXX_COMPILER=cl.exe')
} else { throw "Unsupported kit: $kitName" }
Push-Location $projectRoot
try {
    & cmake --preset $Configuration "-DCMAKE_PREFIX_PATH=$QtRoot" @extra
    if ($LASTEXITCODE) { throw 'CMake configure failed.' }
    & cmake --build --preset $Configuration --parallel 6
    if ($LASTEXITCODE) { throw 'Build failed.' }
    if (-not $SkipTests) {
        & ctest --preset $Configuration
        if ($LASTEXITCODE) { throw 'Tests failed.' }
    }
    Write-Host "Built with $QtRoot. Run build/$Configuration/CopyPop.exe (with Qt bin in PATH), or scripts/package.ps1."
} finally { Pop-Location }
