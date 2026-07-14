param(
  [Parameter(Mandatory = $true)]
  [string]$FfmpegPath
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$imagesDirectory = Join-Path $projectRoot 'assets\images'
$videosDirectory = Join-Path $projectRoot 'assets\videos'
New-Item -ItemType Directory -Path $videosDirectory -Force | Out-Null

for ($screen = 1; $screen -le 5; $screen++) {
  $inputPath = Join-Path $imagesDirectory "onboarding_$screen.png"
  $outputPath = Join-Path $videosDirectory "onboarding_$screen.mp4"
  if (-not (Test-Path -LiteralPath $inputPath)) {
    throw "Missing onboarding artwork: $inputPath"
  }

  $filters = [System.Collections.Generic.List[string]]::new()
  $filters.Add("[0:v]scale=w='trunc(1058*(1+0.02*(1-cos(2*PI*t/6))/2)/2)*2':h=-2:eval=frame,format=rgba[art]")
  $filters.Add("color=c=0x0D0F0E:s=1080x1920:r=30:d=6,format=rgba[background]")
  $filters.Add("[background][art]overlay=x='(W-w)/2+4*sin(2*PI*t/6+$screen)':y='(H-h)/2+3*cos(2*PI*t/6+$screen)':shortest=1[scene]")

  $filters.Add("nullsrc=s=700x700:r=30:d=6,format=rgba,geq=r=34:g=197:b=94:a='18*exp(-((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2))/(2*150*150))'[ambient]")
  $filters.Add("[scene][ambient]overlay=x='190+55*sin(2*PI*t/6+$screen)':y='390+45*cos(2*PI*t/6+$screen)':shortest=1[with_ambient]")

  $filters.Add("color=c=white@0.028:s=130x2200:r=30:d=6,format=rgba,rotate=0.28:ow=rotw(iw):oh=roth(ih):c=none,gblur=sigma=48[sweep]")
  $filters.Add("[with_ambient][sweep]overlay=x='-520+(1740*t/6)':y=-190:shortest=1[with_sweep]")

  $current = 'with_sweep'
  for ($particle = 0; $particle -lt 16; $particle++) {
    $color = if (($particle % 4) -eq 0) { 'white' } else { '0x8BEA78' }
    $opacity = 0.10 + (($particle % 3) * 0.025)
    $size = 4 + ($particle % 3)
    $baseX = 45 + (($particle * 137 + $screen * 43) % 960)
    $baseY = 70 + (($particle * 211 + $screen * 67) % 1420)
    $xAmplitude = 3 + ($particle % 5)
    $yAmplitude = 5 + ($particle % 7)
    $cycles = 1 + ($particle % 2)
    $phase = [math]::Round(($particle * 0.47) + ($screen * 0.31), 2)
    $particleLabel = "particle_$particle"
    $next = "particles_$particle"
    $filters.Add("color=c=$color@$opacity`:s=${size}x${size}:r=30:d=6,format=rgba,gblur=sigma=1.5[$particleLabel]")
    $filters.Add("[$current][$particleLabel]overlay=x='$baseX+$xAmplitude*sin($cycles*2*PI*t/6+$phase)':y='$baseY+$yAmplitude*cos($cycles*2*PI*t/6+$phase)':shortest=1[$next]")
    $current = $next
  }

  $filters.Add("[$current]eq=brightness='0.006*sin(2*PI*t/6)':eval=frame,vignette=PI/8:eval=frame,format=yuv420p[outv]")
  $filterGraph = $filters -join ';'

  & $FfmpegPath `
    -hide_banner `
    -loglevel warning `
    -y `
    -loop 1 `
    -framerate 30 `
    -i $inputPath `
    -filter_complex $filterGraph `
    -map '[outv]' `
    -frames:v 180 `
    -an `
    -c:v libx264 `
    -preset slow `
    -crf 20 `
    -profile:v high `
    -level 4.1 `
    -pix_fmt yuv420p `
    -movflags +faststart `
    $outputPath

  if ($LASTEXITCODE -ne 0) {
    throw "FFmpeg failed while generating $outputPath"
  }
}
