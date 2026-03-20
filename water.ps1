# ==========================================================
# FORTNITE PERFORMANCE & LATENCY OPTIMIZATION SCRIPT
# Target: Windows 10 | Focus: FPS, Input Lag, Responsiveness
# ==========================================================
# --- COOL TITLE GLITCH EFFECT START ---
$TitleText = "juegosboti.xyz"

$GlitchJob = Start-Job -ScriptBlock {
    param($text)
    while ($true) {
        $glitched = ""
        foreach ($char in $text.ToCharArray()) {
            # 50/50 chance to uppercase or lowercase
            if ((Get-Random -Minimum 0 -Maximum 2) -eq 1) {
                $glitched += $char.ToString().ToUpper()
            } else {
                $glitched += $char.ToString().ToLower()
            }
        }
        $host.UI.RawUI.WindowTitle = $glitched
        Start-Sleep -Milliseconds 150 # Speed of the glitch
    }
} -ArgumentList $TitleText

Clear-Host
Write-Host "Initializing Optimization..." -ForegroundColor Cyan
# --- COOL TITLE GLITCH EFFECT END ---

# [Your existing optimization code goes here]

# IMPORTANT: Kill the glitch job at the very end of your script 
# so the CPU doesn't keep cycling after you're done:
# Stop-Job $GlitchJob | Remove-Job
Clear-Host

Write-Host "This is free if you paid you got scammed - made & hosted in juegosboti.xyz" -ForegroundColor Cyan

# 1. MOUSE & KEYBOARD PRECISION (Reduce Input Lag)
# Disables Enhance Pointer Precision (Acceleration) and tweaks response times
Write-Host "[*] Tweaking Mouse and Keyboard settings..." -ForegroundColor Yellow
$MousePath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $MousePath -Name "MouseSpeed" -Value "0"
Set-ItemProperty -Path $MousePath -Name "MouseThreshold1" -Value "0"
Set-ItemProperty -Path $MousePath -Name "MouseThreshold2" -Value "0"

# Keyboard Response (Repeat Delay and Rate)
$KeyPath = "HKCU:\Control Panel\Accessibility\Keyboard Response"
if (!(Test-Path $KeyPath)) { New-Item -Path $KeyPath -Force }
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31"

# 2. DELAY REDUCTION (System & Network)
# Disables Nagle's Algorithm for lower networking ping (Gaming focus)
Write-Host "[*] Reducing Network and System Latency..." -ForegroundColor Yellow
$Nics = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
foreach ($Nic in $Nics) {
    Set-ItemProperty -Path $Nic.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $Nic.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
}

# 3. PERFORMANCE ENHANCEMENTS (FPS & Power)
# Set Power Plan to High Performance
Write-Host "[*] Activating High Performance Power Plan..." -ForegroundColor Yellow
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 

# Disable unnecessary Visual Effects (keeps font smoothing for readability)
Write-Host "[*] Optimizing Visual Effects for Performance..." -ForegroundColor Yellow
$VisualPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-ItemProperty -Path $VisualPath -Name "VisualFXSetting" -Value 2

# 4. SYSTEM INTEGRITY & SAFETY (Service Optimization)
# Disables non-essential "bloat" services that cause micro-stutters
Write-Host "[*] Managing Background Services..." -ForegroundColor Yellow
$Services = @("SysMain", "DiagTrack", "RemoteRegistry", "WbioSrvc")
foreach ($Svc in $Services) {
    if (Get-Service $Svc -ErrorAction SilentlyContinue) {
        Stop-Service $Svc -Force -ErrorAction SilentlyContinue
        Set-Service $Svc -StartupType Disabled
    }
}

# 5. FORTNITE SPECIFIC: GAME PRIORITY
# Tells Windows to give more CPU cycles to Fortnite when it's running
Write-Host "[*] Setting Fortnite CPU Priority to High..." -ForegroundColor Yellow
$FortniteReg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FortniteClient-Win64-Shipping.exe\PerfOptions"
if (!(Test-Path $FortniteReg)) { New-Item -Path $FortniteReg -Force }
Set-ItemProperty -Path $FortniteReg -Name "CpuPriorityClass" -Value 3

Write-Host "Optimization Complete! Please restart your PC for all changes to apply." -ForegroundColor Green
Stop-Job $GlitchJob | Remove-Job
