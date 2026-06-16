# capture_screenshots.ps1
# Run this from the project root with your Android device connected via USB.
# It launches each screen of Kalani's Word World and saves screenshots to .\showcase\images\

$pkg = "com.example.talkingwithkalani"
$activity = "$pkg/.MainActivity"
$out = "$PSScriptRoot\images"

function Shot($name) {
    Start-Sleep -Milliseconds 1800
    adb shell screencap -p /sdcard/shot.png
    adb pull /sdcard/shot.png "$out\$name.png"
    adb shell rm /sdcard/shot.png
    Write-Host "Captured: $name.png"
}

Write-Host "Checking device..."
adb devices

Write-Host "`nLaunching app..."
adb shell am start -n $activity
Shot "01_home"

Write-Host "Opening vocabulary picker..."
adb shell input tap 540 1200   # approximate tap on "Vocabulary" card
Shot "02_vocab_picker"

Write-Host "Going back to home..."
adb shell input keyevent 4
Start-Sleep -Milliseconds 800

Write-Host "Opening Alphabet Challenge..."
adb shell input tap 540 1400
Shot "03_alphabet"

Write-Host "Going back..."
adb shell input keyevent 4
Start-Sleep -Milliseconds 800

Write-Host "Opening Shapes & Colors..."
adb shell input tap 200 1400
Shot "04_shapes"

Write-Host "Going back..."
adb shell input keyevent 4
Start-Sleep -Milliseconds 800

Write-Host "Opening Picture Puzzle..."
adb shell input tap 880 1400
Shot "05_puzzle"

Write-Host "Going back..."
adb shell input keyevent 4
Start-Sleep -Milliseconds 800

Write-Host "Opening Memory Game..."
adb shell input tap 540 1600
Shot "06_memory"

Write-Host "`nDone! Screenshots saved to $out"
Write-Host "NOTE: Tap coordinates are approximate. If any screen missed, retake manually with:"
Write-Host "  adb shell screencap -p /sdcard/shot.png && adb pull /sdcard/shot.png showcase\images\<name>.png"
