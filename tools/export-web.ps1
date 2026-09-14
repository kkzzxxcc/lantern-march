param([string]$Godot = (Join-Path $PSScriptRoot '..\.tools\godot\Godot_v4.6-stable_win64_console.exe'), [switch]$Debug)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Godot = [IO.Path]::GetFullPath($Godot)
Push-Location $projectRoot
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $projectRoot '.tools\userdata'
    New-Item -ItemType Directory -Force -Path 'build/web', 'artifacts', $env:APPDATA | Out-Null
    if (-not (Test-Path -LiteralPath '.tools/templates/web_nothreads_release.zip')) {
        & node tools/download-templates.mjs
        if ($LASTEXITCODE -ne 0) { throw 'Template download failed.' }
    }
    $exportFlag = if ($Debug) { '--export-debug' } else { '--export-release' }
    & $Godot --headless --path $projectRoot $exportFlag Web --log-file (Join-Path $projectRoot 'artifacts/export-web.log')
    if ($LASTEXITCODE -ne 0) { throw 'Web export failed.' }
    if (Select-String -LiteralPath 'artifacts/export-web.log' -Pattern 'SCRIPT ERROR|Export failed') { throw 'Script or export errors were logged.' }
    & node tools/finalize-web.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Web finalization failed.' }
    Write-Output 'Web export ready in build/web. Run: node tools/serve.mjs build/web 8060'
} finally {
    $env:APPDATA = $previousAppData
    Pop-Location
}

