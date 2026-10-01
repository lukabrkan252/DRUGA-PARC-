@echo off
title MO planiranje - pokretanje
set "DEST=C:\MO_planiranje"
if /i not "%~dp0"=="%DEST%\" (
  echo Kopiram aplikaciju u %DEST% ...
  robocopy "%~dp0." "%DEST%" /E /NFL /NDL /NJH /NJS /NP /XF mo.db postavke.cmd nalozi.xlsx preostala_norma.xlsx >nul
  if not exist "%DEST%\data" mkdir "%DEST%\data"
  if not exist "%DEST%\data\nalozi.xlsx" copy /y "%~dp0data\nalozi.xlsx" "%DEST%\data\" >nul
  if not exist "%DEST%\data\preostala_norma.xlsx" copy /y "%~dp0data\preostala_norma.xlsx" "%DEST%\data\" >nul
)
cd /d "%DEST%"
call "windows\Napravi_ikonu_na_desktopu.bat" /nopause
call "windows\MO_planiranje.bat"
echo.
echo GOTOVO. Odsad koristite ikonu "MO planiranje" na Desktopu.
timeout /t 8 >nul
