param([string]$Godot = (Join-Path $PSScriptRoot '..\.tools\godot\Godot_v4.6-stable_win64_console.exe'))
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Godot = [IO.Path]::GetFullPath($Godot)
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Set -Godot to a Godot 4.6 stable executable.' }
Push-Location $projectRoot
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $projectRoot '.tools\userdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA, (Join-Path $projectRoot 'artifacts') | Out-Null
    & $Godot --headless --path $projectRoot --editor --import --quit --log-file (Join-Path $projectRoot 'artifacts\import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/presentation_test.gd --log-file (Join-Path $projectRoot 'artifacts\presentation-tests.log')
    if ($LASTEXITCODE -ne 0) { throw 'Korean/audio presentation tests failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/test_runner.gd --log-file (Join-Path $projectRoot 'artifacts\tests.log')
    if ($LASTEXITCODE -ne 0) { throw 'Gameplay tests failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/save_probe.gd --log-file (Join-Path $projectRoot 'artifacts\save-write.log') -- write
    if ($LASTEXITCODE -ne 0) { throw 'Save write probe failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/save_probe.gd --log-file (Join-Path $projectRoot 'artifacts\save-read.log') -- read
    if ($LASTEXITCODE -ne 0) { throw 'Fresh-process save load failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/audit_suite.gd --log-file (Join-Path $projectRoot 'artifacts\audit-tests.log')
    if ($LASTEXITCODE -ne 0) { throw 'Focused audit suite failed.' }
    & $Godot --headless --path $projectRoot --fixed-fps 60 --script res://tests/runtime_e2e.gd --log-file (Join-Path $projectRoot 'artifacts\runtime-e2e.log')
    if ($LASTEXITCODE -ne 0) { throw 'Real physics E2E failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/runtime_e2e.gd --log-file (Join-Path $projectRoot 'artifacts\runtime-e2e-reload.log') -- read
    if ($LASTEXITCODE -ne 0) { throw 'Runtime cross-process persistence failed.' }
    & $Godot --headless --path $projectRoot --fixed-fps 60 --script res://tests/runtime_e2e.gd --log-file (Join-Path $projectRoot 'artifacts\boss-runtime.log') -- boss
    if ($LASTEXITCODE -ne 0) { throw 'Boss runtime failed.' }
    $logPaths = @('presentation-tests.log','boss-runtime.log','import.log','tests.log','save-write.log','save-read.log','audit-tests.log','runtime-e2e.log','runtime-e2e-reload.log') | ForEach-Object { Join-Path $projectRoot ('artifacts\' + $_) }
    $errorLines = Select-String -Path $logPaths -Pattern 'SCRIPT ERROR|ERROR:|WARNING:' | Where-Object { $_.Line -notmatch 'Failed to read the root certificate store' }
    if ($errorLines) { $errorLines | ForEach-Object { Write-Output $_ }; throw 'Unexpected Godot error/warning in logs.' }
    Write-Output 'All checks passed. See artifacts/test-results.json. A sandbox certificate-store warning, if present, is explicitly excluded.'
} finally {
    $env:APPDATA = $previousAppData
    Pop-Location
}

