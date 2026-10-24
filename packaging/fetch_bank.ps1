# Downloads the current Exam'1 question bank (published by the REF for the web and
# Android versions) into packaging\data, so that it is bundled with the installer.
# Usage: powershell -ExecutionPolicy Bypass -File packaging\fetch_bank.ps1 [-BaseUrl <url>]
param([string]$BaseUrl = "https://exam1.r-e-f.org/assets/")

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Invoke-WebRequest (Windows PowerShell 5.1) does not compare the number of bytes received
# with the Content-Length announced by the server: a connection cut short during the
# 35 MB image archive leaves a truncated file without any error. This downloader checks
# the size, resumes an incomplete file with an HTTP Range request and retries a few times.
function Save-Url([string]$Url, [string]$Path, [int]$Attempts = 5) {
    $total = -1L
    $lastError = ""
    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        $have = 0L
        if (Test-Path -LiteralPath $Path) { $have = (Get-Item -LiteralPath $Path).Length }
        if ($total -lt 0 -or $have -ge $total) {
            # Nothing usable to resume from: start again from the beginning.
            Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
            $have = 0L
        }
        $completed = $false
        try {
            $req = [Net.HttpWebRequest]::Create($Url)
            $req.UserAgent = "Exam1-fetch_bank"
            $req.Timeout = 60000
            $req.ReadWriteTimeout = 60000
            $req.AutomaticDecompression = [Net.DecompressionMethods]::None
            if ($have -gt 0) {
                $req.AddRange($have)
                Write-Host ("  resuming at {0:N1} MB" -f ($have / 1MB))
            }
            $resp = $req.GetResponse()
            try {
                $append = ($have -gt 0) -and ($resp.StatusCode -eq [Net.HttpStatusCode]::PartialContent)
                if (-not $append) {
                    # Full response (first attempt, or a server that ignores Range).
                    $have = 0L
                    $total = $resp.ContentLength
                }
                $mode = if ($append) { [IO.FileMode]::Append } else { [IO.FileMode]::Create }
                $out = New-Object IO.FileStream($Path, $mode, [IO.FileAccess]::Write)
                $in = $resp.GetResponseStream()
                try {
                    $buffer = New-Object byte[] 262144
                    $done = $have
                    $shown = 0L
                    while (($n = $in.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        $out.Write($buffer, 0, $n)
                        $done += $n
                        if ($total -gt 0 -and $done - $shown -ge 1MB) {
                            $shown = $done
                            Write-Progress -Activity "Downloading $Url" -Status ("{0:N1} / {1:N1} MB" -f ($done / 1MB), ($total / 1MB)) `
                                -PercentComplete ([int](100 * $done / $total))
                        }
                    }
                } finally {
                    $in.Dispose()
                    $out.Dispose()
                    Write-Progress -Activity "Downloading $Url" -Completed
                }
                $completed = $true
            } finally {
                $resp.Close()
            }
        } catch {
            $err = $_.Exception
            while ($err.InnerException) { $err = $err.InnerException }
            $lastError = $err.Message
            $web = $_.Exception
            while ($web -and -not ($web -is [Net.WebException])) { $web = $web.InnerException }
            if ($web -and $web.Response) {
                $code = [int]$web.Response.StatusCode
                # Client errors other than timeout / bad range will not go away by retrying.
                if ($code -ge 400 -and $code -lt 500 -and $code -ne 408 -and $code -ne 416) {
                    throw "$Url : HTTP $code"
                }
                if ($code -eq 416) { $total = -1L }
            }
        }
        $size = 0L
        if (Test-Path -LiteralPath $Path) { $size = (Get-Item -LiteralPath $Path).Length }
        if ($total -ge 0 -and $size -eq $total) { return $size }
        if ($total -lt 0 -and $completed -and $size -gt 0) { return $size }  # size not announced
        if ($total -ge 0) {
            Write-Warning ("{0}: attempt {1}/{2}, {3} of {4} bytes received. {5}" -f $Url, $attempt, $Attempts, $size, $total, $lastError)
        } else {
            Write-Warning ("{0}: attempt {1}/{2} failed. {3}" -f $Url, $attempt, $Attempts, $lastError)
        }
        if ($attempt -lt $Attempts) { Start-Sleep -Seconds (2 * $attempt) }
    }
    throw "$Url : download incomplete after $Attempts attempts"
}

function Get-HexHead([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    try {
        $bytes = New-Object byte[] 16
        $n = $stream.Read($bytes, 0, 16)
        if ($n -le 0) { return "(empty file)" }
        return (($bytes[0..($n - 1)] | ForEach-Object { $_.ToString("X2") }) -join " ")
    } finally {
        $stream.Dispose()
    }
}

$dest = Join-Path $PSScriptRoot "data"
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("exam1-bank-" + [Guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $dest, $tmp | Out-Null
$ok = $false
try {
    foreach ($f in "questions.json", "series.json", "questions.zip") {
        Write-Host "Downloading $BaseUrl$f"
        $size = Save-Url ($BaseUrl + $f) (Join-Path $tmp $f)
        Write-Host ("  {0:N0} bytes" -f $size)
    }

    $json = Get-Content -Raw -Encoding UTF8 (Join-Path $tmp "questions.json") | ConvertFrom-Json
    if (-not $json.questions -or $json.questions.Count -eq 0) { throw "questions.json contains no question" }
    Write-Host ("questions.json: version {0}, {1} questions" -f $json.version, $json.questions.Count)

    $zipPath = Join-Path $tmp "questions.zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    } catch {
        throw ("questions.zip is not a valid ZIP archive ({0:N0} bytes, starts with {1}; a ZIP file starts with 50 4B 03 04)" -f `
            (Get-Item -LiteralPath $zipPath).Length, (Get-HexHead $zipPath))
    }
    try {
        Write-Host ("questions.zip: {0} files" -f $zip.Entries.Count)
    } finally {
        $zip.Dispose()
    }

    Move-Item -Force (Join-Path $tmp "*") $dest
    Write-Host "Question bank stored in $dest"
    $ok = $true
} finally {
    if ($ok) {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    } else {
        Write-Host "Downloaded files kept for inspection in $tmp"
    }
}
