param([switch]$VerifyOnly, [int]$Port = 8060)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { Write-Host 'Node.js 20 or newer is required. Install from https://nodejs.org and run this file again.'; exit 1 }
$url = "http://127.0.0.1:$Port/"
$occupied = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($occupied) { throw "Port $Port is busy. Close the existing server before starting this copy." }
$arguments = @(('"{0}"' -f (Join-Path $root 'tools\serve.mjs')), ('"{0}"' -f (Join-Path $root 'build\web')), "$Port")
$proc = Start-Process -FilePath $node.Source -ArgumentList $arguments -PassThru -WindowStyle Hidden
try {
    $ready = $false
    for ($i=0; $i -lt 30; $i++) {
        try { $response=Invoke-WebRequest -Uri $url -UseBasicParsing; if ($response.StatusCode -eq 200) { $ready=$true; break } } catch { Start-Sleep -Milliseconds 100 }
    }
    if (-not $ready) { throw 'Local server did not start.' }
    if ($VerifyOnly) { Write-Output 'LAUNCHER SERVER CHECK PASS (browser-open step intentionally skipped in automated probe)'; return }
    Start-Process $url
    Write-Host "Lantern March is running at $url"
    Read-Host 'Keep this window open while playing. Press Enter to stop the local server'
} finally { if (-not $proc.HasExited) { Stop-Process -Id $proc.Id } }
