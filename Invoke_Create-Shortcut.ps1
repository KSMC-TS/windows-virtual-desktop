$command= "PowerShell.exe -command `"(Invoke-WebRequest 'https://hcmintune.blob.core.windows.net/scripts/MSRDC_Create-Shortcut.ps1' -UseBasicParsing | Invoke-Expression )`""
$regKeyLocation="HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if (-not(Test-Path -Path $regKeyLocation)){ New-ItemProperty -Path $regKeyLocation -Force }
Set-ItemProperty -Path $regKeyLocation -Name "MSRDC-Create-Shortcut" -Value $command -Force
Invoke-Command -scriptblock ([scriptblock]::Create($command))