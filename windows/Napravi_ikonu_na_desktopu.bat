@echo off
rem Pravi precicu "MO planiranje" sa ikonom na Desktopu (a na serveru i automatsko pokretanje sa Windowsom).
cd /d "%~dp0.."
set "ROOT=%CD%"
if not exist "postavke.cmd" call "windows\Postavi.bat"
call "postavke.cmd"
powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\MO planiranje.lnk'); $s.TargetPath='%ROOT%\windows\MO_planiranje.bat'; $s.WorkingDirectory='%ROOT%'; $s.IconLocation='%ROOT%\assets\icon.ico'; $s.WindowStyle=7; $s.Description='MO planiranje'; $s.Save()"
if /i "%MODE%"=="server" powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Startup')+'\MO planiranje server.lnk'); $s.TargetPath='%ROOT%\windows\MO_planiranje.bat'; $s.Arguments='/auto'; $s.WorkingDirectory='%ROOT%'; $s.IconLocation='%ROOT%\assets\icon.ico'; $s.WindowStyle=7; $s.Save()"
echo.
echo Ikona "MO planiranje" je napravljena na Desktopu.
if /i "%MODE%"=="server" echo Server se od sada pokrece automatski kad se ovaj racunar upali i prijavite se.
if /i not "%~1"=="/nopause" pause
