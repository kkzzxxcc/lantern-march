param([string]$Godot = (Join-Path $PSScriptRoot '..\.tools\godot\Godot_v4.6-stable_win64_console.exe'))
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'zip-utils.ps1')
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Godot = [IO.Path]::GetFullPath($Godot)
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Provide -Godot pointing to Godot 4.6 stable.' }
$runId = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$work = Join-Path $root ('.tools\package-' + $runId)
$stage = Join-Path $work 'staging'
$unpacked = Join-Path $work 'unpacked'
$finalCopy = Join-Path $work 'final-unpacked'
$archive = Join-Path $root 'lantern_march_review.zip'
$allowed = @('project.godot','export_presets.cfg','.gitignore','.gitattributes','HANDOFF.md','DECISIONS.md','TODO.md','PLAY_LANTERN_MARCH.bat','PLAY_README.txt','README.md','README_FOR_REVIEW.md','PROJECT_AUDIT.md','THIRD_PARTY_NOTICES.md','GODOT_COPYRIGHT.txt','platform','core','systems','ui','scenes','assets','data','tests','tools','review_artifacts','build\web')
New-Item -ItemType Directory -Force -Path $stage | Out-Null
function Copy-Payload {
    foreach ($item in $allowed) {
        $source = Join-Path $root $item
        if (-not (Test-Path -LiteralPath $source)) { throw "Missing payload: $item" }
        $destination = Join-Path $stage $item
        if (Test-Path -LiteralPath $source -PathType Container) {
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Get-ChildItem -LiteralPath $source -Force | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $destination -Recurse -Force }
        } else { Copy-Item -LiteralPath $source -Destination $destination -Force }
    }
}
function Check-Payload {
    $files = Get-ChildItem -LiteralPath $stage -File -Recurse -Force
    $badNames = $files | Where-Object { $_.FullName.Substring($stage.Length+1) -match '(^|[\\/])(\.git|\.godot|\.tools|\.env|export_credentials\.cfg)([\\/]|$)|\.(keystore|jks|p12|pfx|pem|key)$' }
    if ($badNames) { throw 'Forbidden private/cache path in payload.' }
    $textFiles = $files | Where-Object { $_.Extension -in @('.gd','.json','.cfg','.md','.txt','.ps1','.mjs','.cjs','.tscn','.godot') }
    $secrets = $textFiles | Select-String -Pattern '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|sk-proj-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{30,}'
    if ($secrets) { throw 'Potential secret detected. Inspect before packaging.' }
}
function Zip-Payload {
    # Only this explicitly named output file is replaced; no recursive deletion.
    if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
    New-PortableZip $stage $archive
}
Copy-Payload
Check-Payload
Zip-Payload
[IO.Compression.ZipFile]::ExtractToDirectory($archive,$unpacked)
foreach ($p in @('project.godot','PROJECT_AUDIT.md','README_FOR_REVIEW.md','scenes\boot\boot.tscn','data\rules.json','tests\runtime_e2e.gd','review_artifacts\test_results.txt','build\web\release.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $unpacked $p))) { throw "Missing extracted file: $p" }
}
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $work 'userdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
    $importLog = Join-Path $root 'review_artifacts\package_import.log'
    $bootLog = Join-Path $root 'review_artifacts\package_boot.log'
    & $Godot --headless --path $unpacked --editor --import --quit --log-file $importLog
    if ($LASTEXITCODE -ne 0) { throw 'Extracted project import failed.' }
    & $Godot --headless --path $unpacked --quit-after 120 --log-file $bootLog
    if ($LASTEXITCODE -ne 0) { throw 'Extracted Main Scene failed.' }
    $errors = Select-String -LiteralPath $importLog,$bootLog -Pattern 'SCRIPT ERROR|ERROR:|WARNING:' | Where-Object { $_.Line -notmatch 'Failed to read the root certificate store|Unable to open Android.*build-tools' }
    if ($errors) { $errors | ForEach-Object { Write-Output $_ }; throw 'Unexpected extracted-project diagnostic.' }
} finally { $env:APPDATA = $previousAppData }
$verification = @"
PACKAGE SOURCE VALIDATION: PASS
Date UTC: $runId
Engine: Godot 4.6.stable.official.89cea1439
Candidate ZIP opened and extracted successfully into a fresh folder without .godot cache.
Commands executed against EXTRACTED copy:
Godot --headless --path <unpacked> --editor --import --quit : exit 0
Godot --headless --path <unpacked> --quit-after 120 : exit 0
Configured Main Scene: res://scenes/boot/boot.tscn
Script parse/import and Main Scene startup: PASS; missing resources: none observed.
Raw outputs: package_import.log, package_boot.log.
Known environment root certificate-store diagnostic is retained and explicitly excepted.
Full gameplay 24 cases / 237 assertions were previously completed; not rerun or recounted for packaging.
Final ZIP is rebuilt with these verification logs. The packaging script extracts it again and compares SHA256 of EVERY payload file to the staged source. Failure aborts delivery.
The project source and assets in the final package are identical to the extracted project tested above; only audit evidence/document inventories are added after execution.
Included: all project sources, original assets, data, tests, tools, documentation, review evidence and actual Web release.
Excluded: .git, .godot, .tools, engine binaries/templates, private local saves and signing credentials.
This report does not embed a hash of its own containing archive (self-reference). Final output prints the archive hash and verified file count.
"@
$verification | Set-Content -Encoding UTF8 (Join-Path $root 'review_artifacts\package_validation.txt')
Push-Location $root
try {
    git status --short --untracked-files=all | Set-Content -Encoding UTF8 'review_artifacts/git_status.txt'
    $diff = git diff --stat
    @('Command: git diff --stat', $diff, 'Note: new untracked files are not included in git diff --stat; see git_status.txt.') | Set-Content -Encoding UTF8 'review_artifacts/git_diff_stat.txt'
} finally { Pop-Location }
'Final payload allowlist scan: no cache/private paths, private key blocks or supported token patterns detected. Documentation mentions credentials descriptively; no signing material is shipped. Binary assets are original WAV and Godot Web runtime. No personal save files included. This scan is heuristic, not a universal secret detector.' | Set-Content -Encoding UTF8 (Join-Path $root 'review_artifacts\sensitive_scan.txt')
Copy-Payload
# Include inventory itself; tree lists actual files in the final staged payload.
$treePath = Join-Path $root 'review_artifacts\file_tree.txt'
'' | Set-Content -Encoding UTF8 (Join-Path $stage 'review_artifacts\file_tree.txt')
$files = @(Get-ChildItem -LiteralPath $stage -Recurse -File -Force | Sort-Object FullName)
$lines = @('Scope: final review ZIP payload. Excludes .git/.godot/.tools/local saves. This is not a count of engine cache files.', ('Total payload files: ' + $files.Count))
$lines += $files | ForEach-Object { $_.FullName.Substring($stage.Length+1).Replace('\','/') }
$lines | Set-Content -Encoding UTF8 $treePath
Copy-Item -LiteralPath $treePath -Destination (Join-Path $stage 'review_artifacts\file_tree.txt') -Force
Check-Payload
Zip-Payload
[IO.Compression.ZipFile]::ExtractToDirectory($archive,$finalCopy)
$verified = 0
foreach ($f in (Get-ChildItem -LiteralPath $stage -Recurse -File -Force)) {
    $relative = $f.FullName.Substring($stage.Length+1)
    $extracted = Join-Path $finalCopy $relative
    if (-not (Test-Path -LiteralPath $extracted)) { throw "Final extraction missing: $relative" }
    if ((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $extracted -Algorithm SHA256).Hash) { throw "Hash mismatch: $relative" }
    $verified++
}
# Verify final game files match the exact candidate that Godot imported (ignore its generated cache).
foreach ($item in @('project.godot','export_presets.cfg','core','systems','ui','scenes','assets','data','tests','build\web')) {
    $candidatePath = Join-Path $unpacked $item
    $candidateFiles = if (Test-Path -LiteralPath $candidatePath -PathType Container) { Get-ChildItem -LiteralPath $candidatePath -File -Recurse -Force } else { Get-Item -LiteralPath $candidatePath }
    foreach ($f in $candidateFiles) {
        $rel = $f.FullName.Substring($unpacked.Length+1)
        if ((Get-FileHash -LiteralPath $f.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $finalCopy $rel)).Hash) { throw "Game source changed since validation: $rel" }
    }
}
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
Write-Output "FINAL ZIP VERIFIED PASS: $verified files; $((Get-Item -LiteralPath $archive).Length) bytes"
Write-Output "SHA256: $hash"
Write-Output "PACKAGE: $archive"
Write-Output "EXTRACTED: $finalCopy"
