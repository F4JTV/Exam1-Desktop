# Downloads the current Exam'1 question bank (published by the REF for the web and
# Android versions) into packaging\data, so that it is bundled with the installer.
# Usage: powershell -ExecutionPolicy Bypass -File packaging\fetch_bank.ps1 [-BaseUrl <url>]
param([string]$BaseUrl = "https://exam1.r-e-f.org/assets/")

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$dest = Join-Path $PSScriptRoot "data"
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("exam1-bank-" + [Guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $dest, $tmp | Out-Null
try {
    foreach ($f in "questions.json", "series.json", "questions.zip") {
        Write-Host "Downloading $BaseUrl$f"
        Invoke-WebRequest -Uri ($BaseUrl + $f) -OutFile (Join-Path $tmp $f) -UseBasicParsing
    }
    $json = Get-Content -Raw -Encoding UTF8 (Join-Path $tmp "questions.json") | ConvertFrom-Json
    if (-not $json.questions -or $json.questions.Count -eq 0) { throw "questions.json contains no question" }
    Write-Host ("questions.json: version {0}, {1} questions" -f $json.version, $json.questions.Count)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $tmp "questions.zip"))
    Write-Host ("questions.zip: {0} files" -f $zip.Entries.Count)
    $zip.Dispose()
    Move-Item -Force (Join-Path $tmp "*") $dest
    Write-Host "Question bank stored in $dest"
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
