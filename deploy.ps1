# deploy.ps1
# Run from the showcase\ folder in PowerShell.
# Does everything: screenshots, git init, create public GitHub repo, push.
#
# Prerequisites:
#   - Android device connected via USB with app installed
#   - GitHub CLI installed (winget install GitHub.cli) and logged in (gh auth login)
#   - Git installed

$ErrorActionPreference = "Stop"
$showcaseDir = $PSScriptRoot
$imagesDir   = "$showcaseDir\images"
$repoName    = "kalani-word-world"
$pkg         = "com.example.talkingwithkalani"

# -- 1. Check tools ------------------------------------------------------------

# Auto-locate adb if not in PATH
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\Sdk\platform-tools\adb.exe",
        "C:\Users\$env:USERNAME\AppData\Local\Android\sdk\platform-tools\adb.exe"
    )
    $adbPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($adbPath) {
        $env:PATH += ";$(Split-Path $adbPath)"
        Write-Host "  Found adb at: $adbPath" -ForegroundColor Cyan
    } else {
        Write-Error "adb not found. Add Android SDK platform-tools to PATH or install Android Studio."
    }
}

foreach ($tool in @("git", "gh")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Error "$tool not found in PATH. Install it and re-run."
    }
}
Write-Host "Tools found" -ForegroundColor Green

# -- 2. Capture screenshots ----------------------------------------------------
New-Item -ItemType Directory -Force -Path $imagesDir | Out-Null

function Shot {
    param($name, $sleepMs = 2000)
    Start-Sleep -Milliseconds $sleepMs
    adb shell screencap -p /sdcard/kww_shot.png
    adb pull /sdcard/kww_shot.png "$imagesDir\$name.png"
    adb shell rm /sdcard/kww_shot.png
    Write-Host "  Captured: $name.png" -ForegroundColor Cyan
}

# Check device is actually online
Write-Host "Checking device connection..." -ForegroundColor Yellow
adb kill-server | Out-Null
Start-Sleep -Milliseconds 1000
adb start-server | Out-Null
Start-Sleep -Milliseconds 1500

$deviceState = adb get-state 2>&1
if ($deviceState -notmatch "device") {
    Write-Error "No device online. Reconnect your phone, accept the USB debugging prompt, and re-run."
}
Write-Host "Device online" -ForegroundColor Green

Write-Host "Launching app..." -ForegroundColor Yellow
adb shell am start -n "$pkg/.MainActivity"
Shot "01_home" 2500

$sizeStr = adb shell wm size
if ($sizeStr -match '(\d+)x(\d+)') {
    $screenW = [int]$Matches[1]
    $screenH = [int]$Matches[2]
} else {
    $screenW = 1080
    $screenH = 2340
}
$cx = [int]($screenW / 2)

Write-Host "Navigating screens..."

adb shell input tap $cx ([int]($screenH * 0.52))
Shot "02_vocab_picker"
adb shell input keyevent 4
Start-Sleep -Milliseconds 600

adb shell input tap $cx ([int]($screenH * 0.62))
Shot "03_alphabet"
adb shell input keyevent 4
Start-Sleep -Milliseconds 600

adb shell input tap ([int]($screenW * 0.28)) ([int]($screenH * 0.72))
Shot "04_shapes"
adb shell input keyevent 4
Start-Sleep -Milliseconds 600

adb shell input tap ([int]($screenW * 0.72)) ([int]($screenH * 0.72))
Shot "05_puzzle"
adb shell input keyevent 4
Start-Sleep -Milliseconds 600

adb shell input tap $cx ([int]($screenH * 0.82))
Shot "06_memory"
adb shell input keyevent 4

Write-Host "Screenshots captured" -ForegroundColor Green

# -- 3. Git init and first commit ----------------------------------------------
Write-Host "Initialising git repo..." -ForegroundColor Yellow
Set-Location $showcaseDir

# Force a clean standalone repo in the showcase folder.
# Without this, git walks up to the parent Android project's .git and commits everything.
if (Test-Path ".git") {
    Remove-Item -Recurse -Force ".git"
}
git init -b main

# Only stage files that belong to this showcase (not parent project files)
git add README.md deploy.ps1 capture_screenshots.ps1 .gitignore
if (Test-Path "images") {
    git add images\
}

git commit -m "Initial showcase - Kalani's Word World"
Write-Host "Committed" -ForegroundColor Green

# -- 4. Create public GitHub repo and push ------------------------------------
Write-Host "Creating public GitHub repo '$repoName'..." -ForegroundColor Yellow

$desc = "Kalani's Word World - Android educational app for early childhood vocabulary (Kotlin + Jetpack Compose)"
gh repo create $repoName --public --description $desc --source . --remote origin --push

Write-Host ""
Write-Host "Done! Public repo live at:" -ForegroundColor Green
gh repo view $repoName --json url -q .url
