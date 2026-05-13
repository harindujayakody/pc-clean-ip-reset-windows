# ================================================================
#  PC Clean & IP Reset  —  Nord Edition
#  by Harindu Jayakody
#
#  Cleans system junk, resets network stack & IP
#  Shows exactly what was deleted and how much space was freed
#
#  Preserves original core:
#    del %temp%  /  C:\Windows\Temp  /  C:\Windows\Prefetch
#    ipconfig /release  /release  /flushdns  /renew
#    netsh winsock reset  /  netsh int ip reset
# ================================================================

# ── Admin check ──────────────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "`n  [!] Please run as Administrator.`n" -ForegroundColor Red
    Pause; Exit
}

# ── Nord colours ─────────────────────────────────────────────
$C = 'Cyan'; $G = 'Green'; $Y = 'Yellow'; $R = 'Red'
$M = 'Magenta'; $W = 'White'; $DG = 'DarkGray'

# ── Fixed table width ────────────────────────────────────────
$IW = 54   # inner width between │ and │

# ════════════════════════════════════════════════════════════
#  UI HELPERS
# ════════════════════════════════════════════════════════════

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $C
    Write-Host "  ║                                                          ║" -ForegroundColor $C
    Write-Host "  ║   ██████╗  ██████╗    ██████╗██╗     ███████╗ █████╗    ║" -ForegroundColor $C
    Write-Host "  ║   ██╔══██╗██╔════╝   ██╔════╝██║     ██╔════╝██╔══██╗   ║" -ForegroundColor $C
    Write-Host "  ║   ██████╔╝██║        ██║     ██║     █████╗  ███████║   ║" -ForegroundColor $C
    Write-Host "  ║   ██╔═══╝ ██║        ██║     ██║     ██╔══╝  ██╔══██║   ║" -ForegroundColor $C
    Write-Host "  ║   ██║     ╚██████╗   ╚██████╗███████╗███████╗██║  ██║   ║" -ForegroundColor $C
    Write-Host "  ║   ╚═╝      ╚═════╝    ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝   ║" -ForegroundColor $C
    Write-Host "  ║                                                          ║" -ForegroundColor $C
    Write-Host "  ║          P C   C L E A N   &   I P   R E S E T          ║" -ForegroundColor $Y
    Write-Host "  ║                    Nord  Edition                        ║" -ForegroundColor $DG
    Write-Host "  ║                                                          ║" -ForegroundColor $C
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $C
    Write-Host ""
    Write-Host "  ► by " -NoNewline -ForegroundColor $DG
    Write-Host "Harindu Jayakody" -ForegroundColor $C
    Write-Host ""
}

function Write-TableTop    { Write-Host "  ╭$('─' * $IW)╮" -ForegroundColor $C }
function Write-TableBottom { Write-Host "  ╰$('─' * $IW)╯" -ForegroundColor $C }
function Write-TableDiv    { Write-Host "  ├$('─' * $IW)┤" -ForegroundColor $C }

function Write-TableHeader($title) {
    $pad = $IW - $title.Length - 2
    Write-Host "  │ " -NoNewline -ForegroundColor $C
    Write-Host $title -NoNewline -ForegroundColor $Y
    Write-Host (" " * $pad) " │" -ForegroundColor $C
}

# label = 28 chars, before = 10 chars, after = 10 chars, freed = 10 chars → total = 28+2+10+2+10+2+10 = 64... scale down
# layout: " icon label(28)  before(9)  after(9)  freed(9) "
function Write-ResultRow($label, $before, $after) {
    $freed   = [math]::Max(0, $before - $after)
    $bStr    = if ($before -gt 0)  { "{0,7:N1} MB" -f $before }  else { "  empty  " }
    $aStr    = if ($after  -gt 0)  { "{0,7:N1} MB" -f $after  }  else { "   0.0 MB" }
    $fStr    = if ($freed  -gt 0)  { "{0,7:N1} MB" -f $freed  }  else { "     —   " }
    $icon    = if ($freed  -gt 0)  { "✔" } else { "·" }
    $iCol    = if ($freed  -gt 0)  { $G  } else { $DG }
    $fCol    = if ($freed  -gt 0)  { $Y  } else { $DG }
    $lCol    = if ($freed  -gt 0)  { $W  } else { $DG }
    $nm      = ("{0,-28}" -f $label.Substring(0, [math]::Min(28, $label.Length)))

    Write-Host "  │ " -NoNewline -ForegroundColor $C
    Write-Host $icon -NoNewline -ForegroundColor $iCol
    Write-Host " $nm" -NoNewline -ForegroundColor $lCol
    Write-Host "  $bStr" -NoNewline -ForegroundColor $DG
    Write-Host "  $aStr" -NoNewline -ForegroundColor $DG
    Write-Host "  $fStr" -NoNewline -ForegroundColor $fCol
    Write-Host " │" -ForegroundColor $C
}

function Write-ColHeader {
    $lbl  = ("{0,-28}" -f "Location")
    Write-Host "  │ " -NoNewline -ForegroundColor $C
    Write-Host "  $lbl" -NoNewline -ForegroundColor $DG
    Write-Host "   Before  " -NoNewline -ForegroundColor $DG
    Write-Host "    After  " -NoNewline -ForegroundColor $DG
    Write-Host "    Freed " -NoNewline -ForegroundColor $DG
    Write-Host " │" -ForegroundColor $C
}

function Write-TotalRow($freed) {
    $fStr = "{0:N2} MB  ({1:N3} GB)" -f $freed, ($freed / 1024)
    $lbl  = " TOTAL FREED  "
    Write-Host "  │" -NoNewline -ForegroundColor $M
    Write-Host $lbl -NoNewline -ForegroundColor $W
    Write-Host ($fStr.PadRight($IW - $lbl.Length)) -NoNewline -ForegroundColor $Y
    Write-Host "│" -ForegroundColor $M
}

function Write-NetRow($label, $status, $col) {
    $nm = ("{0,-30}" -f $label)
    Write-Host "  │  " -NoNewline -ForegroundColor $C
    Write-Host $nm -NoNewline -ForegroundColor $W
    Write-Host ("{0,-$($IW - 34)}" -f $status) -NoNewline -ForegroundColor $col
    Write-Host "  │" -ForegroundColor $C
}

function Write-ScanLine($label) {
    Write-Host ("  ● {0,-22}" -f $label) -NoNewline -ForegroundColor $DG
    Write-Host "scanning..." -ForegroundColor $DG
}

# ════════════════════════════════════════════════════════════
#  SIZE HELPER  (files only — no dir Length errors)
# ════════════════════════════════════════════════════════════

function Get-FolderSize($path) {
    if (-not (Test-Path $path)) { return [double]0 }
    $sum = (Get-ChildItem $path -Recurse -Force -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    return [math]::Round($(if ($sum) { $sum / 1MB } else { 0 }), 2)
}

function Remove-FolderAndRecreate($path) {
    # Mirrors original BAT: del /s/f/q + rd /s/q + mkdir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        return [double]0
    }
    $before = Get-FolderSize $path
    Get-ChildItem $path -Recurse -Force -File -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $after = Get-FolderSize $path
    # Ensure folder still exists (mirrors mkdir in original)
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
    $freed = $before - $after
    return [PSCustomObject]@{
        Before = $before
        After  = Get-FolderSize $path
        Freed  = [math]::Round($(if ($freed -gt 0) { $freed } else { 0 }), 2)
    }
}

# ════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════

Write-Banner

# ── STEP 1: Measure BEFORE ───────────────────────────────────
Write-Host "  ► Measuring current junk..." -ForegroundColor $W
Write-Host ""

$targets = @(
    [PSCustomObject]@{ Label = "User Temp (%TEMP%)"; Path = $env:TEMP }
    [PSCustomObject]@{ Label = "Windows Temp";        Path = "C:\Windows\Temp" }
    [PSCustomObject]@{ Label = "Prefetch Cache";      Path = "C:\Windows\Prefetch" }
)

foreach ($t in $targets) {
    Write-ScanLine $t.Label
    $t | Add-Member -NotePropertyName SizeBefore -NotePropertyValue (Get-FolderSize $t.Path)
}

$totalBefore = [double]0
$targets | ForEach-Object { $totalBefore += $_.SizeBefore }

Write-Host ""
Write-Host "  ► Found " -NoNewline -ForegroundColor $W
Write-Host ("{0:N2} MB" -f $totalBefore) -NoNewline -ForegroundColor $Y
Write-Host " of junk to clean." -ForegroundColor $W
Write-Host ""
Write-Host "  ► " -NoNewline -ForegroundColor $C
Write-Host "Proceed? " -NoNewline -ForegroundColor $W
Write-Host "[Y] Yes   [N] No  :  " -NoNewline -ForegroundColor $Y
$confirm = Read-Host
if ($confirm -notmatch "^[Yy]$") {
    Write-Host "`n  ○ Cancelled. Nothing changed.`n" -ForegroundColor $Y
    Pause; Exit
}

# ════════════════════════════════════════════════════════════
#  STEP 2: CLEAN JUNK
# ════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  ╭── CLEANING SYSTEM JUNK $('─' * 30)╮" -ForegroundColor $C
Write-Host "  │" -ForegroundColor $C

foreach ($t in $targets) {
    Write-Host ("  │  ► Cleaning {0,-28}" -f $t.Label) -NoNewline -ForegroundColor $DG
    $result = Remove-FolderAndRecreate $t.Path
    $t | Add-Member -NotePropertyName SizeAfter -NotePropertyValue $result.After
    $t | Add-Member -NotePropertyName Freed     -NotePropertyValue $result.Freed
    if ($result.Freed -gt 0) {
        Write-Host ("{0:N2} MB freed" -f $result.Freed) -ForegroundColor $G
    } else {
        Write-Host "already clean" -ForegroundColor $DG
    }
}

Write-Host "  │" -ForegroundColor $C
Write-Host "  ╰$('─' * $IW)╯" -ForegroundColor $C

# ════════════════════════════════════════════════════════════
#  STEP 3: NETWORK RESET  (original core — unchanged)
# ════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  ╭── RESETTING NETWORK $('─' * 33)╮" -ForegroundColor $C
Write-Host "  │" -ForegroundColor $C

$netSteps = @(
    @{ Label = "Releasing IP address";     Cmd = { ipconfig /release   2>&1 | Out-Null } }
    @{ Label = "Flushing DNS cache";       Cmd = { ipconfig /flushdns  2>&1 | Out-Null } }
    @{ Label = "Renewing IP address";      Cmd = { ipconfig /renew     2>&1 | Out-Null } }
    @{ Label = "Resetting Winsock";        Cmd = { netsh winsock reset  2>&1 | Out-Null } }
    @{ Label = "Resetting TCP/IP stack";   Cmd = { netsh int ip reset   2>&1 | Out-Null } }
)

$netResults = @()
foreach ($step in $netSteps) {
    Write-Host ("  │  ► {0,-32}" -f $step.Label) -NoNewline -ForegroundColor $DG
    try {
        & $step.Cmd
        Write-Host "done" -ForegroundColor $G
        $netResults += [PSCustomObject]@{ Label=$step.Label; Status="done"; OK=$true }
    } catch {
        Write-Host "failed" -ForegroundColor $R
        $netResults += [PSCustomObject]@{ Label=$step.Label; Status="failed"; OK=$false }
    }
}

Write-Host "  │" -ForegroundColor $C
Write-Host "  ╰$('─' * $IW)╯" -ForegroundColor $C

# ════════════════════════════════════════════════════════════
#  STEP 4: SUMMARY REPORT
# ════════════════════════════════════════════════════════════

$totalFreed = [double]0
$targets | ForEach-Object { $totalFreed += $_.Freed }

Write-Host ""
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $M
Write-Host "  ║                    SUMMARY REPORT                       ║" -ForegroundColor $M
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $M

# ── Junk table ───────────────────────────────────────────────
Write-Host ""
Write-TableTop
Write-TableHeader "SYSTEM JUNK CLEANED"
Write-TableDiv
Write-ColHeader
Write-TableDiv

foreach ($t in $targets) {
    Write-ResultRow $t.Label $t.SizeBefore $t.SizeAfter
}

Write-TableDiv
Write-TotalRow $totalFreed
Write-TableBottom

# ── Network table ────────────────────────────────────────────
Write-Host ""
Write-TableTop
Write-TableHeader "NETWORK RESET"
Write-TableDiv

foreach ($n in $netResults) {
    $col = if ($n.OK) { $G } else { $R }
    $icon = if ($n.OK) { "✔" } else { "✖" }
    $nm   = ("{0,-44}" -f $n.Label)
    Write-Host "  │ " -NoNewline -ForegroundColor $C
    Write-Host "$icon " -NoNewline -ForegroundColor $col
    Write-Host $nm -NoNewline -ForegroundColor $W
    Write-Host "  │" -ForegroundColor $C
}

Write-TableBottom

# ── Final box ────────────────────────────────────────────────
$sStr  = "{0:N2} MB  ({1:N3} GB)" -f $totalFreed, ($totalFreed / 1024)
$label = " ✔  Freed:  "

Write-Host ""
Write-Host "  ╭$('─' * $IW)╮" -ForegroundColor $G
Write-Host "  │" -NoNewline -ForegroundColor $G
Write-Host $label -NoNewline -ForegroundColor $W
Write-Host ($sStr.PadRight($IW - $label.Length)) -NoNewline -ForegroundColor $Y
Write-Host "│" -ForegroundColor $G
Write-Host "  │" -NoNewline -ForegroundColor $G
Write-Host " ✔  Network stack has been reset.".PadRight($IW) -NoNewline -ForegroundColor $G
Write-Host "│" -ForegroundColor $G
Write-Host "  │" -NoNewline -ForegroundColor $G
Write-Host " ⚠  Reboot recommended for network changes.".PadRight($IW) -NoNewline -ForegroundColor $Y
Write-Host "│" -ForegroundColor $G
Write-Host "  ╰$('─' * $IW)╯" -ForegroundColor $G

Write-Host ""
Write-Host "  by Harindu Jayakody" -ForegroundColor $DG
Write-Host ""
Pause
