# compress-video.ps1
# Compresses "Live Demo.mp4" to under 25 MB for GitHub upload

$ErrorActionPreference = "Stop"

$ffmpeg  = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0.1-full_build\bin\ffmpeg.exe"
$ffprobe = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0.1-full_build\bin\ffprobe.exe"

$inputFile  = "G:\TaxPrime\pitch-deck\Live Demo.mp4"
$outputFile = "G:\TaxPrime\pitch-deck\live-demo.mp4"
$passlog    = "G:\TaxPrime\pitch-deck\ffmpeg2pass"

# Validate tools exist
if (!(Test-Path -LiteralPath $ffmpeg))  { throw "ffmpeg not found at $ffmpeg" }
if (!(Test-Path -LiteralPath $ffprobe)) { throw "ffprobe not found at $ffprobe" }

# Get duration in seconds
$duration = [double](& $ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $inputFile)
Write-Host "Duration: $duration seconds"

# Calculate bitrates to hit ~24 MB target
$targetSizeMB    = 24
$audioKbps       = 64
$targetTotalKbps = [math]::Floor(($targetSizeMB * 1024 * 1024 * 8) / $duration / 1000)
$videoKbps       = [math]::Max($targetTotalKbps - $audioKbps, 300)

Write-Host "Target total: ${targetTotalKbps} kbps, Video: ${videoKbps} kbps, Audio: ${audioKbps} kbps"

# Clean up old pass logs
Remove-Item -ErrorAction SilentlyContinue "${passlog}-0.log", "${passlog}-0.log.mbtree"

# Pass 1
Write-Host "Running pass 1..."
& $ffmpeg -y -i $inputFile -vf "scale=-2:720" -c:v libx264 -pix_fmt yuv420p `
    -b:v "${videoKbps}k" -maxrate "${videoKbps}k" -bufsize "${videoKbps}k" `
    -preset veryfast -pass 1 -passlogfile $passlog -an -f mp4 NUL

# Pass 2
Write-Host "Running pass 2..."
& $ffmpeg -y -i $inputFile -vf "scale=-2:720" -c:v libx264 -pix_fmt yuv420p `
    -b:v "${videoKbps}k" -maxrate "${videoKbps}k" -bufsize "${videoKbps}k" `
    -preset veryfast -pass 2 -passlogfile $passlog `
    -c:a aac -b:a "${audioKbps}k" -movflags +faststart $outputFile

# Show result
$info = Get-Item -LiteralPath $outputFile
Write-Host "`nDone! Output file:"
Write-Host "  Name: $($info.Name)"
Write-Host "  Size: $([math]::Round($info.Length / 1MB, 2)) MB"
