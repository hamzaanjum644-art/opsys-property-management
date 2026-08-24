<#
    Opsys Pro - encoding repair

    WHAT WENT WRONG
    The install scripts wrote files as UTF-8. Some were later round-tripped
    through Windows PowerShell 5.1's Get-Content / Set-Content, which reads as
    Windows-1252 and writes as UTF-8. Every non-ASCII character was therefore
    re-encoded twice:  ·  became  Â·  ,  —  became  â€"  ,  →  became  â†' .

    THE FIX
    Rather than replacing each broken sequence by hand, this reverses the exact
    transformation: read the text, encode it back to Windows-1252 bytes, then
    decode those bytes as UTF-8. That recovers every affected character in one
    pass, including ones not listed above.

    SAFETY
    Files with no corruption are skipped entirely, so this is safe to run twice.

    USAGE
        .\fix-encoding.ps1
#>

$ErrorActionPreference = 'Stop'
$root = "D:\dev\opsys-property-management"

if (-not (Test-Path (Join-Path $root 'package.json'))) {
    Write-Host "  Project not found at $root" -ForegroundColor Red
    exit 1
}

$utf8  = New-Object System.Text.UTF8Encoding($false)
$w1252 = [System.Text.Encoding]::GetEncoding(1252)

$targets = Get-ChildItem -Path (Join-Path $root 'app'),
                               (Join-Path $root 'components'),
                               (Join-Path $root 'lib'),
                               (Join-Path $root 'prisma') `
                         -Recurse -File -Include *.tsx, *.ts, *.css, *.sql `
                         -ErrorAction SilentlyContinue

$fixed = 0
$clean = 0

Write-Host ""
Write-Host "  Repairing character encoding" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $targets) {
    $text = [System.IO.File]::ReadAllText($file.FullName, $utf8)

    # Only touch files that actually show the corruption signature.
    # Â and â are the tell-tale first bytes of a double-encoded sequence.
    if ($text -notmatch '[\u00C2\u00E3\u00E2]') {
        $clean++
        continue
    }

    $repaired = $utf8.GetString($w1252.GetBytes($text))

    # If the round-trip produced replacement characters, the file was not
    # actually double-encoded - leave it untouched rather than damage it.
    if ($repaired.Contains([char]0xFFFD)) {
        Write-Host "  [skip] $($file.Name) - not double-encoded" -ForegroundColor Yellow
        continue
    }

    [System.IO.File]::WriteAllText($file.FullName, $repaired, $utf8)
    Write-Host "  [fix ] $($file.FullName.Substring($root.Length + 1))" -ForegroundColor Green
    $fixed++
}

Write-Host ""
Write-Host "  $fixed repaired, $clean already clean" -ForegroundColor White
Write-Host ""

if ($fixed -gt 0) {
    Write-Host "  Next:" -ForegroundColor Cyan
    Write-Host "    git add -A"
    Write-Host "    git commit -m ""Fix character encoding"""
    Write-Host "    git push"
    Write-Host ""
}
