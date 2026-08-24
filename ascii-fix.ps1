<#
    Opsys Pro - permanent encoding fix

    ROOT CAUSE
    Windows PowerShell 5.1 reads .ps1 files as Windows-1252 unless they carry a
    byte-order mark. The installer scripts were UTF-8, so characters like the
    em dash were corrupted as PowerShell parsed the script - before a single
    file was written. Every downstream fix inherited the same fault, because
    those scripts were UTF-8 too.

    THE FIX
    This script contains no non-ASCII characters at all. Every character it
    searches for is built from an explicit code point, so PowerShell cannot
    misread it. It replaces the four typographic characters - and their
    corrupted forms - with plain ASCII equivalents that can never break again.

        em dash      ->  -
        middle dot   ->  |
        right arrow  ->  ->
        ellipsis     ->  ...

    Safe to run repeatedly.

    USAGE
        .\ascii-fix.ps1
#>

$ErrorActionPreference = 'Stop'
$root = "D:\dev\opsys-property-management"

if (-not (Test-Path (Join-Path $root 'package.json'))) {
    Write-Host "  Project not found at $root" -ForegroundColor Red
    exit 1
}

# Build every search string from code points so this file stays pure ASCII.
$emdash  = [string][char]0x2014
$middot  = [string][char]0x00B7
$arrow   = [string][char]0x2192
$ellipsis = [string][char]0x2026

# The corrupted forms: UTF-8 bytes misread as Windows-1252.
$badDash  = [string][char]0x00E2 + [char]0x20AC + [char]0x201D
$badDot   = [string][char]0x00C2 + [char]0x00B7
$badArrow = [string][char]0x00E2 + [char]0x2020 + [char]0x2019
$badEllip = [string][char]0x00E2 + [char]0x20AC + [char]0x00A6

$pairs = @(
    @{ From = $badDash;  To = '-' },
    @{ From = $badDot;   To = '|' },
    @{ From = $badArrow; To = '->' },
    @{ From = $badEllip; To = '...' },
    @{ From = $emdash;   To = '-' },
    @{ From = $middot;   To = '|' },
    @{ From = $arrow;    To = '->' },
    @{ From = $ellipsis; To = '...' }
)

$utf8 = New-Object System.Text.UTF8Encoding($false)

$targets = Get-ChildItem -Path (Join-Path $root 'app'),
                               (Join-Path $root 'components'),
                               (Join-Path $root 'lib'),
                               (Join-Path $root 'prisma') `
                         -Recurse -File -Include *.tsx, *.ts, *.css, *.sql `
                         -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  Converting source to plain ASCII" -ForegroundColor Cyan
Write-Host ""

$changed = 0

foreach ($file in $targets) {
    $text = [System.IO.File]::ReadAllText($file.FullName, $utf8)
    $original = $text

    foreach ($pair in $pairs) {
        $text = $text.Replace($pair.From, $pair.To)
    }

    if ($text -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $text, $utf8)
        $rel = $file.FullName.Substring($root.Length + 1)
        Write-Host "  [fixed] $rel" -ForegroundColor Green
        $changed++
    }
}

Write-Host ""
Write-Host "  $changed files updated" -ForegroundColor White

# Verify nothing non-ASCII survives.
$remaining = 0
foreach ($file in $targets) {
    $text = [System.IO.File]::ReadAllText($file.FullName, $utf8)
    foreach ($ch in $text.ToCharArray()) {
        if ([int]$ch -gt 127) {
            $rel = $file.FullName.Substring($root.Length + 1)
            Write-Host "  [left ] $rel still contains U+$('{0:X4}' -f [int]$ch)" -ForegroundColor Yellow
            $remaining++
            break
        }
    }
}

Write-Host ""
if ($remaining -eq 0) {
    Write-Host "  All source files are now pure ASCII. This cannot recur." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Next:" -ForegroundColor Cyan
    Write-Host "    git add -A"
    Write-Host "    git commit -m ""Convert source to ASCII"""
    Write-Host "    git push"
} else {
    Write-Host "  $remaining file(s) still contain non-ASCII characters." -ForegroundColor Yellow
}
Write-Host ""
