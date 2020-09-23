param ([Parameter(Mandatory=$true)][string]$workspace,$folder)
$workspacename = "$workspace (RD)"
$appdatapath = "$env:appdata\Microsoft\Windows\Start Menu\Programs\$workspacename*"
$userappdatapath = Get-ChildItem $appdatapath | Select-Object FullName
$userdesktop = [Environment]::GetFolderPath("Desktop")
$Shortcutfile = "$userdesktop\$workspacename.lnk"
$appfile = "C:\Program Files\Remote Desktop\msrdcw.exe"
$startup = "$env:appdata\Microsoft\Windows\Start Menu\Programs\Remote Desktop.lnk"
[string]$userappdatapath = Get-ChildItem $appdatapath

if (!(Test-Path $startup)) {
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($startup)
    $Shortcut.TargetPath = $appfile
    $Shortcut.Save()
}


if (Test-Path $userappdatapath) {

    if ($folder -eq $true) {
        if (!(Test-Path $ShortcutFile)) {
            $WScriptShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
            $Shortcut.TargetPath = $userappdatapath
            $Shortcut.Save()
        }
    }
    $appshortcuts = Get-ChildItem -Path $userappdatapath\*.lnk
    $desktopshortcuts = Get-ChildItem -Path $userdesktop\*$workspace*.lnk -Exclude "$WorkspaceName.lnk"
    foreach ($desktopshortcut in $desktopshortcuts) {
        $filename = $desktopshortcut.PSChildName
        $pathcheck = "$userappdatapath\$filename"
        if (!(Test-Path $pathcheck)) { Remove-Item $desktopshortcut -Force }
    }
    foreach ($appshortcut in $appshortcuts) {
        if(!(Test-Path $userdesktop\$appshortcut.Name)) {
            Copy-Item $appshortcut $userdesktop -Force
        } else {
        #    Remove-Item $userdesktop\$appshortcut.Name -Force
        #    Copy-Item $appshortcut $userdesktop -Force
        }

    }

} else {
    Write-Host "Please Sign into Microsoft Remote Desktop Client and try again"
    Start-Process -FilePath "C:\Program Files\Remote Desktop\msrdcw.exe"
}