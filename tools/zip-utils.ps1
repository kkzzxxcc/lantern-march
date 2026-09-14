Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
function New-PortableZip([string]$Directory, [string]$Archive) {
    if (Test-Path -LiteralPath $Archive) { Remove-Item -LiteralPath $Archive -Force }
    $zip = [IO.Compression.ZipFile]::Open($Archive, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in (Get-ChildItem -LiteralPath $Directory -Recurse -File -Force)) {
            $name = $file.FullName.Substring($Directory.Length+1).Replace('\','/')
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,$name,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    } finally { $zip.Dispose() }
    $check = [IO.Compression.ZipFile]::OpenRead($Archive)
    try { foreach ($entry in $check.Entries) { if ($entry.FullName.Contains('\')) { throw 'ZIP backslash entry found.' } } } finally { $check.Dispose() }
}

