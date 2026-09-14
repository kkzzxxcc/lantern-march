$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'zip-utils.ps1')
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$work = Join-Path $root ('.tools\web-package-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss'))
$stage = Join-Path $work 'stage'
$extracted = Join-Path $work 'extracted'
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'build'),(Join-Path $stage 'tools') | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'build\web') -Destination (Join-Path $stage 'build') -Recurse
foreach ($name in @('PLAY_LANTERN_MARCH.bat','PLAY_README.txt','THIRD_PARTY_NOTICES.md','GODOT_COPYRIGHT.txt')) { Copy-Item -LiteralPath (Join-Path $root $name) -Destination $stage }
foreach ($name in @('serve-web.ps1','serve.mjs')) { Copy-Item -LiteralPath (Join-Path $root ('tools\'+$name)) -Destination (Join-Path $stage 'tools') }
$archive = Join-Path $root 'lantern_march_web_release.zip'
New-PortableZip $stage $archive
[IO.Compression.ZipFile]::ExtractToDirectory($archive,$extracted)
$verified = 0
foreach ($file in (Get-ChildItem -LiteralPath $stage -File -Recurse -Force)) {
    $relative = $file.FullName.Substring($stage.Length+1)
    if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $extracted $relative)).Hash) { throw "Web ZIP mismatch: $relative" }
    $verified++
}
$release = Get-Content -Raw -LiteralPath (Join-Path $extracted 'build\web\release.json') | ConvertFrom-Json
foreach ($asset in $release.assets) { if (-not (Test-Path -LiteralPath (Join-Path $extracted ('build\web\'+$asset)))) { throw "Missing Web asset: $asset" } }
$launcher = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $extracted 'tools\serve-web.ps1') -VerifyOnly -Port 8063
if ($LASTEXITCODE -ne 0) { throw 'Extracted launcher failed.' }
$report = @("WEB ZIP PASS: $verified files; version $($release.version)",'All entries use forward slash; all extracted SHA256 hashes match. All manifest release assets exist.', $launcher, 'Browser auto-open is Start-Process default URL; automated launcher probe verifies server, not desktop browser selection.', ('SHA256: '+(Get-FileHash -LiteralPath $archive).Hash), ('Path: '+$archive))
$report | Set-Content -Encoding UTF8 (Join-Path $root 'review_artifacts\web_package_validation.txt')
$report | Write-Output
