@echo off
rem Pokretac. Server: pokrene aplikaciju ako ne radi i otvori je. Klijent: samo otvori adresu servera.
cd /d "%~dp0.."
if not exist "postavke.cmd" call "windows\Postavi.bat"
call "postavke.cmd"
if /i "%MODE%"=="client" (
  start "" "http://%SERVER%/"
  exit /b 0
)

if not exist ".venv\Scripts\python.exe" (
  echo Prvo pokretanje - priprema aplikacije, sacekajte nekoliko minuta...
  py -3 -c "import sys; sys.exit(0 if sys.version_info>=(3,10) else 1)" || (echo Potreban je Python 3.10 ili noviji ^(python.org, oznacite "Add to PATH"^). & pause & exit /b 1)
  py -3 -m venv .venv || (pause & exit /b 1)
  ".venv\Scripts\python.exe" -m pip install -q -r requirements.txt || (echo Instalacija nije uspjela - provjerite internet. & pause & exit /b 1)
)
powershell -NoProfile -Command "if (-not (Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue)) { exit 1 }"
if errorlevel 1 (
  start "MO planiranje server (ne zatvarati)" /min ".venv\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port %PORT%
)
powershell -NoProfile -Command "$ip=(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1 -ExpandProperty IPAddress); \"$ip`:%PORT%\" | Set-Content -Encoding ascii adresa_servera.txt"
powershell -NoProfile -Command "for($i=0;$i -lt 90;$i++){ try { Invoke-WebRequest -UseBasicParsing http://localhost:%PORT%/ -TimeoutSec 2 | Out-Null; exit 0 } catch { Start-Sleep 1 } }; exit 1"
if /i not "%~1"=="/auto" start "" "http://localhost:%PORT%/"
