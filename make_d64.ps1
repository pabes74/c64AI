# C64 PRG-to-D64 PowerShell script (FIXED QUOTES)

$vicePath = "..\SDL2VICE-3.10-win64\c1541.exe"
$prgFolder = "prg"
$d64Folder = "d64"
$d64File = Join-Path $d64Folder "c64stuff.d64"

Write-Host "Creating/overwriting $d64File with all PRG files from $prgFolder..."


# Ensure d64 output folder exists
if (!(Test-Path $d64Folder)) {
    New-Item -ItemType Directory -Path $d64Folder | Out-Null
}

# Create/overwrite D64 image
& $vicePath -format "c64stuff,01" d64 $d64File

Get-ChildItem -Path $prgFolder -Filter *.prg | ForEach-Object {
    $baseName = $_.BaseName.ToLower()
    
    # Safe truncate + C64-safe chars only
    if ($baseName.Length -gt 15) { $baseName = $baseName.Substring(0,15) }
    
    $safeName = ""
    foreach ($char in $baseName.ToCharArray()) {
        if (($char -ge [char]'a' -and $char -le [char]'z') -or 
            ($char -ge [char]'0' -and $char -le [char]'9') -or
            $char -in @(' ','.','-','$')) {
            $safeName += $char
        } else {
            $safeName += '_'
        }
    }
    
    if ([string]::IsNullOrWhiteSpace($safeName) -or $safeName.Length -eq 0) {
        $safeName = "FILE"
    } else {
        $safeName = $safeName.Trim().Substring(0, [Math]::Min(15, $safeName.Length))
    }
    
    Write-Host "Adding $($_.Name) as `"$safeName`"..."
    # DOUBLE ESCAPE the quotes for c1541.exe
    & $vicePath -attach $d64File -write $_.FullName $safeName
}

Write-Host "`nDirectory listing:" -ForegroundColor Cyan
& $vicePath -attach $d64File -dir

Write-Host "`nDone! Attach $d64File in VICE Drive 8 and LOAD *,8,1" -ForegroundColor Green
Read-Host "Press Enter to exit"
