@echo off
rem Pokretac: po potrebi pripremi okruzenje, pokrene server (ako vec ne radi) i otvori web aplikaciju.
cd /d "%~dp0.."
set PORT=8000
if not exist ".venv\Scripts\python.exe" (
  echo Prvo pokretanje - priprema aplikacije, sacekajte...
  py -3 -m venv .venv || (echo Nije pronadjen Python 3. Instalirajte ga sa python.org ^(oznacite "Add to PATH"^). & pause & exit /b 1)
  ".venv\Scripts\python.exe" -m pip install -q -r requirements.txt || (echo Instalacija nije uspjela - provjerite internet. & pause & exit /b 1)
)
powershell -NoProfile -Command "if (-not (Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue)) { exit 1 }"
if errorlevel 1 (
  start "MO planiranje server" /min ".venv\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port %PORT%
)
powershell -NoProfile -Command "for($i=0;$i -lt 60;$i++){ try { Invoke-WebRequest -UseBasicParsing http://localhost:%PORT%/ -TimeoutSec 2 | Out-Null; exit 0 } catch { Start-Sleep 1 } }; exit 1"
start "" "http://localhost:%PORT%/"
