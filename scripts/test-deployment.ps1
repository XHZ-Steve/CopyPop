param([string]$Directory)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
if(-not $Directory){$Directory=Join-Path $projectRoot 'dist/CopyPop-1.0.0-windows-x64'}
$exe=Join-Path $Directory 'CopyPop.exe'
$qa=Join-Path $projectRoot 'build/deployment-qa'
New-Item -ItemType Directory -Force -Path $qa | Out-Null
$oldPath=$env:PATH; $oldPlugins=$env:QT_PLUGIN_PATH; $oldQml=$env:QML_IMPORT_PATH; $oldQml2=$env:QML2_IMPORT_PATH
try{
    $env:PATH="$env:SystemRoot/System32;$env:SystemRoot"; $env:QT_PLUGIN_PATH=$null; $env:QML_IMPORT_PATH=$null; $env:QML2_IMPORT_PATH=$null
    foreach($mode in 'light','dark'){
        $config=Join-Path $qa "$mode.json"
        @{schemaVersion=1;global=@{firstRun=$false;startup=$false;theme=$mode};applications=@()} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $config -Encoding utf8
        foreach($page in 0..7){
            $errors=Join-Path $qa "$mode-$page.stderr.txt"
            $args=@('--smoke-test','--test-config',$config,'--test-page',"$page",'--screenshot',(Join-Path $qa "$mode-$page.png"))
            $p=Start-Process -FilePath $exe -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardError $errors
            if(-not $p.WaitForExit(15000)){ $p.Kill(); throw "Smoke test timed out: $mode $page" }
            $p.Refresh()
            if($p.ExitCode -ne 0 -or (Get-Content -LiteralPath "$config.smoke-result" -Raw).Trim() -ne 'PASS'){throw "Smoke test failed: $mode $page"}
            if((Get-Item -LiteralPath $errors).Length -gt 0){throw "Runtime warnings: $errors"}
        }
    }
    $welcomeConfig=Join-Path $qa 'welcome.json'
    @{schemaVersion=1;global=@{theme='light'};applications=@()} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $welcomeConfig -Encoding utf8
    $args=@('--smoke-test','--welcome','--test-config',$welcomeConfig,'--screenshot',(Join-Path $qa 'welcome.png'))
    $welcome=Start-Process -FilePath $exe -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardError (Join-Path $qa 'welcome.stderr.txt')
    if(-not $welcome.WaitForExit(15000)){ $welcome.Kill(); throw 'Welcome smoke test timeout' }
    $welcome.Refresh(); if($welcome.ExitCode -ne 0){throw 'Welcome smoke test failed'}
    $instance=Join-Path $qa 'instance.json'
    @{schemaVersion=1;global=@{firstRun=$false;startup=$false};applications=@()} | ConvertTo-Json | Set-Content -LiteralPath $instance -Encoding utf8
    $ipcScreenshot=Join-Path $qa 'ipc-settings.png'
    if(Test-Path -LiteralPath $ipcScreenshot){Remove-Item -LiteralPath $ipcScreenshot -Force}
    $first=Start-Process -FilePath $exe -ArgumentList '--background','--test-config',$instance,'--test-instance','--screenshot',(Join-Path $qa 'ipc-settings.png') -WindowStyle Hidden -PassThru
    try{
        $null=$first.WaitForExit(650)
        $second=Start-Process -FilePath $exe -ArgumentList '--test-config',$instance,'--test-instance' -WindowStyle Hidden -PassThru
        if(-not $second.WaitForExit(5000)){ $second.Kill(); throw 'Second instance did not exit' }
        $second.Refresh(); if($second.ExitCode -ne 0){ throw 'IPC forwarding failed' }
        $null=$first.WaitForExit(2000)
        if(-not (Test-Path -LiteralPath (Join-Path $qa 'ipc-settings.png'))){throw 'IPC did not wake settings'}
        $first.Refresh(); $cpuBefore=$first.TotalProcessorTime.TotalMilliseconds
        $null=$first.WaitForExit(3000); $first.Refresh()
        "Idle CPU time over 3 seconds: $([Math]::Round($first.TotalProcessorTime.TotalMilliseconds-$cpuBefore)) ms; working set: $([Math]::Round($first.WorkingSet64/1MB)) MB" | Set-Content -LiteralPath (Join-Path $qa 'performance.txt')
    } finally { if(-not $first.HasExited){$first.Kill(); $first.WaitForExit()} }
    Write-Host "PASS: 16 themed pages, welcome, native overlay and isolated single-instance IPC. Evidence: $qa"
}finally{
    $env:PATH=$oldPath; $env:QT_PLUGIN_PATH=$oldPlugins; $env:QML_IMPORT_PATH=$oldQml; $env:QML2_IMPORT_PATH=$oldQml2
}
