$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'zip-utils.ps1')
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$work=Join-Path $root ('.tools\migration-'+[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss'))
$stage=Join-Path $work 'stage'
$extracted=Join-Path $work 'extracted'
$sealed=Join-Path $work 'sealed'
$archive=Join-Path $root 'lantern_march_openclaw_handoff.zip'
New-Item -ItemType Directory -Force -Path $stage | Out-Null
$include=@('artifacts\.gdignore','core','systems','ui','scenes','data','platform','tests','tools','assets','review_artifacts','build\web','project.godot','export_presets.cfg','.gitignore','.gitattributes','AGENTS.md','HANDOFF.md','DECISIONS.md','TODO.md','PROJECT_AUDIT.md','README_FOR_REVIEW.md','OPENCLAW_MIGRATION.md','README.md','PLAY_README.txt','PLAY_LANTERN_MARCH.bat','THIRD_PARTY_NOTICES.md','GODOT_COPYRIGHT.txt')
if(Test-Path -LiteralPath (Join-Path $root 'lantern_march_git.bundle')) { $include+='lantern_march_git.bundle' }
foreach($item in $include){
    $source=Join-Path $root $item
    if(-not(Test-Path -LiteralPath $source)){throw "Missing source: $item"}
    $dest=Join-Path $stage $item
    if(Test-Path -LiteralPath $source -PathType Container){
        New-Item -ItemType Directory -Force -Path $dest | Out-Null
        Get-ChildItem -LiteralPath $source -Force | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force }
    } else { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null; Copy-Item -LiteralPath $source -Destination $dest }
}
$files=@(Get-ChildItem -LiteralPath $stage -Recurse -File -Force)
$bad=$files | Where-Object { $_.FullName.Substring($stage.Length+1) -match '(^|[\\/])(\.git|\.godot|\.tools|\.env|export_credentials\.cfg)([\\/]|$)|\.(keystore|jks|pfx|p12|pem|key)$' }
if($bad){throw 'Forbidden cache or credential path.'}
$textFiles=$files | Where-Object {$_.Extension -in @('.md','.txt','.gd','.tscn','.json','.cfg','.godot','.ps1','.mjs','.cjs')}
$secrets=$textFiles | Select-String -Pattern '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|sk-proj-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{30,}|mfa\.[A-Za-z0-9_-]{40,}'
if($secrets){throw 'Potential secret detected; inspect before delivery.'}
New-PortableZip $stage $archive
[IO.Compression.ZipFile]::ExtractToDirectory($archive,$extracted)
foreach($name in @('project.godot','AGENTS.md','HANDOFF.md','DECISIONS.md','TODO.md','PROJECT_AUDIT.md','README_FOR_REVIEW.md','OPENCLAW_MIGRATION.md','core\unit\unit_base.gd','tests\runtime_e2e.gd','build\web\release.json')){
    if(-not(Test-Path -LiteralPath (Join-Path $extracted $name))){throw "Extracted file missing: $name"}
}
$verified=0
foreach($f in $files){
    $rel=$f.FullName.Substring($stage.Length+1)
    if((Get-FileHash -LiteralPath $f.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $extracted $rel)).Hash){throw "Hash mismatch: $rel"}
    $verified++
}
$bundleResult='NOT AVAILABLE; consult migration_git.txt.'
if(Test-Path -LiteralPath (Join-Path $extracted 'lantern_march_git.bundle')){
    $clone=Join-Path $work 'bundle-clone'
    $cloneLog = & git clone --quiet (Join-Path $extracted 'lantern_march_git.bundle') $clone 2>&1
    if($LASTEXITCODE -ne 0){throw "Bundle clone failed: $cloneLog"}
    Push-Location $clone
    try{
        $commit=git rev-parse HEAD
        $tracked=git ls-files
        foreach($rel in $tracked){
            $payload=Join-Path $extracted $rel
            if(-not(Test-Path -LiteralPath $payload)){throw "Committed file absent from ZIP: $rel"}
            $payloadBlob=git hash-object --path=$rel $payload
            $committedBlob=git rev-parse ("HEAD:"+$rel)
            if($payloadBlob -ne $committedBlob){throw "Bundle/payload content mismatch: $rel"}
        }
    }finally{Pop-Location}
    $bundleResult="PASS: extracted bundle cloned successfully; HEAD $commit; all tracked Git blobs match ZIP after .gitattributes normalization."
}
$report=@('OPENCLAW MIGRATION PACKAGE: PASS',('Verified payload files before adding attestation: '+$verified),'Actual ZIP extraction succeeded; all required onboarding/source/test files exist.','All SHA256 file comparisons passed. ZIP entry separators are forward slashes.','No excluded cache/credential paths or scanned private-key/token patterns found. Scan is heuristic.',('Bundle restoration: '+$bundleResult),'Gameplay source preserved; no new feature/native work or repeated gameplay test run in migration pass.','Latest recorded gameplay suite:24 cases /237 assertions /0 failures.','Final seal adds this report, then extracts and hashes every payload file again. A failure aborts packaging.')
$reportPath=Join-Path $root 'review_artifacts\migration_validation.txt'
$report | Set-Content -Encoding UTF8 $reportPath
Copy-Item -LiteralPath $reportPath -Destination (Join-Path $stage 'review_artifacts\migration_validation.txt') -Force
New-PortableZip $stage $archive
[IO.Compression.ZipFile]::ExtractToDirectory($archive,$sealed)
$count=0
foreach($f in (Get-ChildItem -LiteralPath $stage -Recurse -File -Force)){
    $rel=$f.FullName.Substring($stage.Length+1)
    if((Get-FileHash -LiteralPath $f.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $sealed $rel)).Hash){throw "Final sealed ZIP mismatch: $rel"}
    $count++
}
Write-Output "MIGRATION ZIP PASS: $count files; $((Get-Item -LiteralPath $archive).Length) bytes"
Write-Output "BUNDLE: $bundleResult"
Write-Output "SHA256: $((Get-FileHash -LiteralPath $archive).Hash)"
Write-Output "ZIP: $archive"



