<#
.SYNOPSIS
    Cleans Windows temporary files and resets the network stack.
.DESCRIPTION
    A Nord-themed terminal maintenance utility that measures and cleans %TEMP%,
    C:\Windows\Temp, and Prefetch caches, then optionally resets the network stack.
.PARAMETER SkipNetwork
    Bypasses ipconfig release/renew and winsock/TCP/IP resets to keep active connections intact.
.PARAMETER DryRun
    Scans and reports junk sizes and steps without deleting files or modifying network settings.
.PARAMETER Yes
    Bypasses interactive confirmation.
#>
[CmdletBinding()]
param(
    [Alias('skip-network', 'no-network')]
    [switch]$SkipNetwork,

    [Alias('dry-run', 'WhatIf')]
    [switch]$DryRun,

    [Alias('y', 'AssumeYes')]
    [switch]$Yes
)

# ---- Admin check ---------------------------------------------
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    if ($DryRun) {
        Write-Host ""
        Write-Host "  [i] Running dry-run without administrator privileges." -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "  [!] Please run as Administrator." -ForegroundColor Red
        Write-Host ""
        Pause; Exit
    }
}

$C  = 'Cyan'; $G = 'Green'; $Y = 'Yellow'
$R  = 'Red';  $M = 'Magenta'; $W = 'White'; $DG = 'DarkGray'

# ==============================================================
#  TABLE LAYOUT
# ==============================================================
$IW = 62   # inner width between the two | characters

function Ln  { Write-Host "  +$('-' * $IW)+" -ForegroundColor $C }
function Ln2 { Write-Host "  +$('=' * $IW)+" -ForegroundColor $M }

function Hdr($title) {
    $pad = $IW - $title.Length - 1
    if ($pad -lt 0) { $pad = 0 }
    Write-Host "  | " -NoNewline -ForegroundColor $C
    Write-Host $title -NoNewline -ForegroundColor $Y
    Write-Host (" " * $pad) -NoNewline
    Write-Host "|" -ForegroundColor $C
}

function ColHdr {
    Write-Host "  | " -NoNewline -ForegroundColor $C
    Write-Host "     " -NoNewline -ForegroundColor $DG
    Write-Host ("{0,-22}" -f "Location") -NoNewline -ForegroundColor $DG
    Write-Host "    Before " -NoNewline -ForegroundColor $DG
    Write-Host "     After " -NoNewline -ForegroundColor $DG
    Write-Host "     Freed " -NoNewline -ForegroundColor $DG
    Write-Host "|" -ForegroundColor $C
}

function DataRow($label, $before, $after, $freed) {
    $icon = $(if ($freed -gt 0) { "[OK]" } else { "[--]" })
    $iCol = $(if ($freed -gt 0) { $G } else { $DG })
    $fCol = $(if ($freed -gt 0) { $Y } else { $DG })
    $lCol = $(if ($freed -gt 0) { $W } else { $DG })
    $bS   = "{0,8:N2}MB" -f $before
    $aS   = "{0,8:N2}MB" -f $after
    $fS   = $(if ($freed -gt 0) { "{0,8:N2}MB" -f $freed } else { "    none  " })
    $nm   = ("{0,-22}" -f $label.Substring(0, [math]::Min(22, $label.Length)))

    Write-Host "  | " -NoNewline -ForegroundColor $C
    Write-Host $icon -NoNewline -ForegroundColor $iCol
    Write-Host " $nm" -NoNewline -ForegroundColor $lCol
    Write-Host "  $bS" -NoNewline -ForegroundColor $DG
    Write-Host "  $aS" -NoNewline -ForegroundColor $DG
    Write-Host "  $fS" -NoNewline -ForegroundColor $fCol
    Write-Host " |" -ForegroundColor $C
}

function TotalRow($freed) {
    $fStr = "{0:N2} MB  ({1:N3} GB)" -f $freed, ($freed / 1024)
    $lbl  = " TOTAL FREED  "
    Write-Host "  |" -NoNewline -ForegroundColor $M
    Write-Host $lbl -NoNewline -ForegroundColor $W
    Write-Host ($fStr.PadRight($IW - $lbl.Length)) -NoNewline -ForegroundColor $Y
    Write-Host "|" -ForegroundColor $M
}

function NetRow($label, $ok) {
    $icon = $(if ($ok) { "[OK]" } else { "[!!]" })
    $col  = $(if ($ok) { $G } else { $R })
    $nm   = ("{0,-54}" -f $label)
    Write-Host "  | " -NoNewline -ForegroundColor $C
    Write-Host $icon -NoNewline -ForegroundColor $col
    Write-Host " $nm" -NoNewline -ForegroundColor $W
    Write-Host " |" -ForegroundColor $C
}

function FinalRow($icon, $text, $iCol, $tCol) {
    $nm = (" $icon $text").PadRight($IW)
    Write-Host "  |" -NoNewline -ForegroundColor $G
    Write-Host $nm -NoNewline -ForegroundColor $tCol
    Write-Host "|" -ForegroundColor $G
}

# ==============================================================
#  SIZE HELPERS
# ==============================================================

function Get-FolderSize($path) {
    if (-not (Test-Path $path)) { return [double]0 }
    $sum = (Get-ChildItem $path -Recurse -Force -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    return [math]::Round($(if ($sum) { $sum / 1MB } else { 0 }), 2)
}

function Clean-Folder($path, [double]$knownBefore = -1, [switch]$IsDryRun) {
    # In dry-run mode, reuse known before size if provided to avoid re-measuring
    $before = $(if ($IsDryRun -and $knownBefore -ge 0) { $knownBefore } else { Get-FolderSize $path })
    if (-not $IsDryRun -and (Test-Path $path)) {
        # Delete files first, then empty dirs
        Get-ChildItem $path -Recurse -Force -File -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
        Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Recreate folder (mirrors original BAT mkdir)
    if (-not $IsDryRun -and (-not (Test-Path $path))) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    # Measure AFTER
    $after = $(if ($IsDryRun) { $before } else { Get-FolderSize $path })
    $freed = $(if ($IsDryRun) { $before } else { $before - $after })
    if ($freed -lt 0) { $freed = 0 }

    return [PSCustomObject]@{
        Before = $before
        After  = [math]::Round($after, 2)
        Freed  = [math]::Round($freed, 2)
    }
}

# ==============================================================
#  BANNER
# ==============================================================

Clear-Host
Write-Host ""
Write-Host "  +$('=' * $IW)+" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "".PadRight($IW) -NoNewline
Write-Host "|" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "       ######   ######     ######  ##      ######   #####     ".PadRight($IW) -NoNewline -ForegroundColor $C
Write-Host "|" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "       ##  ##  ##          ##      ##      ##      ##   ##    ".PadRight($IW) -NoNewline -ForegroundColor $C
Write-Host "|" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "       ######  ##          ##      ##      ####    #######    ".PadRight($IW) -NoNewline -ForegroundColor $C
Write-Host "|" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "       ##      ##          ##      ##      ##      ##   ##    ".PadRight($IW) -NoNewline -ForegroundColor $C
Write-Host "|" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "       ##       ######      ######  ######  ######  ##   ##    ".PadRight($IW) -NoNewline -ForegroundColor $C
Write-Host "|" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "".PadRight($IW) -NoNewline
Write-Host "|" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "           PC CLEAN  &  IP RESET  --  Nord Edition           ".PadRight($IW) -NoNewline -ForegroundColor $Y
Write-Host "|" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "                     by Harindu Jayakody                     ".PadRight($IW) -NoNewline -ForegroundColor $DG
Write-Host "|" -ForegroundColor $C
Write-Host "  |" -NoNewline -ForegroundColor $C
Write-Host "".PadRight($IW) -NoNewline
Write-Host "|" -ForegroundColor $C
Write-Host "  +$('=' * $IW)+" -ForegroundColor $C
Write-Host ""

# ==============================================================
#  STEP 1: SCAN
# ==============================================================

$targets = @(
    [PSCustomObject]@{ Label = "User Temp (%TEMP%)"; Path = $env:TEMP              }
    [PSCustomObject]@{ Label = "Windows Temp";        Path = "C:\Windows\Temp"      }
    [PSCustomObject]@{ Label = "Prefetch Cache";      Path = "C:\Windows\Prefetch"  }
)

Write-Host "  >> Measuring system junk..." -ForegroundColor $W
Write-Host ""

foreach ($t in $targets) {
    Write-Host ("  >> {0,-25}" -f $t.Label) -NoNewline -ForegroundColor $DG
    $sz = Get-FolderSize $t.Path
    $t | Add-Member -NotePropertyName SizeBefore -NotePropertyValue $sz
    Write-Host ("{0:N2} MB found" -f $sz) -ForegroundColor $C
}

$totalBefore = [double]0
$targets | ForEach-Object { $totalBefore += $_.SizeBefore }

Write-Host ""
Write-Host "  >> Total found: " -NoNewline -ForegroundColor $W
Write-Host ("{0:N2} MB" -f $totalBefore) -ForegroundColor $Y

if (-not $SkipNetwork) {
    Write-Host ""
    Write-Host "  [!] WARNING: Network reset will temporarily disconnect your internet." -ForegroundColor $Y
    Write-Host "      Active downloads, VPNs, and remote sessions (RDP/SSH) will be interrupted." -ForegroundColor $DG
    Write-Host "      (Use -SkipNetwork to clean junk files without touching the network)" -ForegroundColor $DG
} else {
    Write-Host ""
    Write-Host "  [i] Network reset is skipped (-SkipNetwork active)." -ForegroundColor $C
}

if ($DryRun) {
    Write-Host ""
    Write-Host "  [i] Dry-run active. No files or network settings will be modified." -ForegroundColor $Y
}

Write-Host ""
if (-not $Yes) {
    Write-Host "  >> Proceed? " -NoNewline -ForegroundColor $C
    Write-Host "[Y] Yes   [N] No  :  " -NoNewline -ForegroundColor $Y
    $confirm = Read-Host

    if ($confirm -notmatch "^[Yy]$") {
        Write-Host ""
        Write-Host "  [--] Cancelled. Nothing was changed." -ForegroundColor $Y
        Write-Host ""
        Pause; Exit
    }
}

# ==============================================================
#  STEP 2: CLEAN
# ==============================================================

Write-Host ""
Write-Host "  +-- CLEANING SYSTEM JUNK $('-' * ($IW - 17))+" -ForegroundColor $C
Write-Host "  |" -ForegroundColor $C

foreach ($t in $targets) {
    Write-Host ("  |  >> {0,-25}" -f $t.Label) -NoNewline -ForegroundColor $DG
    $r = Clean-Folder $t.Path -knownBefore $t.SizeBefore -IsDryRun:$DryRun
    $t | Add-Member -NotePropertyName SizeAfter -NotePropertyValue $r.After
    $t | Add-Member -NotePropertyName Freed     -NotePropertyValue $r.Freed
    if ($DryRun) {
        Write-Host ("{0:N2} MB would be freed (dry-run)" -f $r.Freed) -ForegroundColor $Y
    } elseif ($r.Freed -gt 0) {
        Write-Host ("{0:N2} MB freed" -f $r.Freed) -ForegroundColor $G
    } else {
        Write-Host "already clean (or files in use)" -ForegroundColor $DG
    }
}

Write-Host "  |" -ForegroundColor $C
Ln

# ==============================================================
#  STEP 3: NETWORK RESET
# ==============================================================

$netResults = [System.Collections.Generic.List[PSCustomObject]]::new()

if (-not $SkipNetwork) {
    Write-Host ""
    Write-Host "  +-- RESETTING NETWORK $('-' * ($IW - 13))+" -ForegroundColor $C
    Write-Host "  |" -ForegroundColor $C

    $netCmds = @(
        [PSCustomObject]@{ Label = "Releasing IP address";   Cmd = "ipconfig /release"    }
        [PSCustomObject]@{ Label = "Flushing DNS cache";     Cmd = "ipconfig /flushdns"   }
        [PSCustomObject]@{ Label = "Renewing IP address";    Cmd = "ipconfig /renew"      }
        [PSCustomObject]@{ Label = "Resetting Winsock";      Cmd = "netsh winsock reset"  }
        [PSCustomObject]@{ Label = "Resetting TCP/IP stack"; Cmd = "netsh int ip reset"   }
    )

    foreach ($step in $netCmds) {
        Write-Host ("  |  >> {0,-32}" -f $step.Label) -NoNewline -ForegroundColor $DG
        if ($DryRun) {
            Write-Host "skipped (dry-run)" -ForegroundColor $Y
            $netResults.Add([PSCustomObject]@{ Label=$step.Label; OK=$true })
        } else {
            try {
                cmd /c $step.Cmd 2>&1 | Out-Null
                Write-Host "done" -ForegroundColor $G
                $netResults.Add([PSCustomObject]@{ Label=$step.Label; OK=$true })
            } catch {
                Write-Host "failed" -ForegroundColor $R
                $netResults.Add([PSCustomObject]@{ Label=$step.Label; OK=$false })
            }
        }
    }

    Write-Host "  |" -ForegroundColor $C
    Ln
} else {
    Write-Host ""
    Write-Host "  +-- NETWORK RESET $('-' * ($IW - 9))+" -ForegroundColor $C
    Write-Host "  |  >> Network reset was skipped (-SkipNetwork parameter)" -ForegroundColor $DG
    Write-Host "  |" -ForegroundColor $C
    Ln
}

# ==============================================================
#  SUMMARY REPORT
# ==============================================================

$totalFreed = [double]0
$targets | ForEach-Object { $totalFreed += $_.Freed }

Write-Host ""
Write-Host ""
Ln2
Hdr "  SUMMARY REPORT"
Ln2

# ---- Junk table ---------------------------------------------
Write-Host ""
Ln
Hdr "SYSTEM JUNK CLEANED"
Ln
ColHdr
Ln

foreach ($t in $targets) {
    DataRow $t.Label $t.SizeBefore $t.SizeAfter $t.Freed
}

Ln
TotalRow $totalFreed
Ln

# ---- Network table ------------------------------------------
if (-not $SkipNetwork) {
    Write-Host ""
    Ln
    Hdr "NETWORK RESET COMMANDS"
    Ln

    foreach ($n in $netResults) {
        NetRow $n.Label $n.OK
    }

    Ln
}

# ---- Final box ----------------------------------------------
$sStr = "{0:N2} MB  ({1:N3} GB)" -f $totalFreed, ($totalFreed / 1024)

Write-Host ""
Write-Host "  +$('=' * $IW)+" -ForegroundColor $G
if ($DryRun) {
    FinalRow "[i]" "Dry-run complete (no changes made)."     $Y $Y
    FinalRow "[i]" "Projected freed: $sStr"                  $Y $Y
} else {
    FinalRow "[OK]" "Freed:  $sStr"                          $G $Y
}
if ($SkipNetwork) {
    FinalRow "[--]" "Network reset was bypassed."             $DG $DG
} elseif ($DryRun) {
    FinalRow "[--]" "Network reset skipped (dry-run)."       $DG $DG
} else {
    FinalRow "[OK]" "Network stack has been reset."          $G $G
    FinalRow "[!!]" "Reboot recommended for network changes." $Y $Y
}
Write-Host "  +$('=' * $IW)+" -ForegroundColor $G

Write-Host ""
Write-Host "  by Harindu Jayakody" -ForegroundColor $DG
Write-Host ""
if (-not $DryRun) {
    Pause
}
