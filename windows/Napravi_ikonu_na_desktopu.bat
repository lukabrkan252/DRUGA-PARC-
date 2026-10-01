@echo off
rem Pravi precicu "MO planiranje" sa ikonom na Desktopu (radi s bilo koje lokacije foldera).
cd /d "%~dp0.."
set "ROOT=%CD%"
powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\MO planiranje.lnk'); $s.TargetPath='%ROOT%\windows\MO_planiranje.bat'; $s.WorkingDirectory='%ROOT%'; $s.IconLocation='%ROOT%\assets\icon.ico'; $s.WindowStyle=7; $s.Description='MO planiranje'; $s.Save()"
echo Ikona "MO planiranje" je napravljena na Desktopu.
pause
