# Path to cc65 tools
$Cc65Root = "..\cc65-snapshot-win32"
$Cc65Bin  = Join-Path $Cc65Root "bin"

$Cl65 = Join-Path $Cc65Bin "cl65.exe"

if (-not (Test-Path $Cl65)) {
    Write-Error "cl65.exe not found at $Cl65. Adjust paths in this script."
    exit 1
}

# Working directories
$ProjectRoot = Get-Location
$PrgDir = Join-Path $ProjectRoot "prg"

# Create prg output directory if not present
if (-not (Test-Path $PrgDir)) {
    New-Item -ItemType Directory -Path $PrgDir | Out-Null
}

# Process all .asm files in current directory
$asmFiles = Get-ChildItem -Path $ProjectRoot -Filter *.asm

if ($asmFiles.Count -eq 0) {
    Write-Host "No .asm files found in $ProjectRoot"
    exit 0
}

foreach ($file in $asmFiles) {
    $outFile = Join-Path $PrgDir ($file.BaseName + ".prg")

    Write-Host "Building $($file.Name) -> $outFile"

    & $Cl65 -t c64 -C $Cc65Root/cfg/c64-asm.cfg -o $outFile $file.FullName

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed for $($file.Name)"
        exit 1
    }
}

Write-Host "Done. Output written to $PrgDir"
