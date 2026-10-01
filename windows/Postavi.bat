@echo off
rem Jednokratno podesavanje: da li je ovaj racunar SERVER (ovdje radi aplikacija i baza) ili KLIJENT (samo otvara server).
cd /d "%~dp0.."
echo.
echo  MO planiranje - podesavanje ovog racunara
echo  ------------------------------------------
echo  SERVER = glavni racunar na kojem radi aplikacija (samo JEDAN u cijeloj firmi)
echo  KLIJENT = racunar poslovodje / operatera (samo otvara aplikaciju sa servera)
echo.
choice /c SK /n /m "Ovaj racunar je (S)erver ili (K)lijent? "
if errorlevel 2 goto klijent
> postavke.cmd echo set "MODE=server"
>> postavke.cmd echo set "PORT=8000"
echo.
echo Otvaram port 8000 u Windows vatrozidu (potvrdite administratorsko odobrenje)...
powershell -NoProfile -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c netsh advfirewall firewall add rule name=\"MO planiranje\" dir=in action=allow protocol=TCP localport=8000'"
goto kraj
:klijent
echo.
set /p "SRV=Upisite adresu servera koju vam je pokazao server racunar (npr. 192.168.0.50:8000): "
> postavke.cmd echo set "MODE=client"
>> postavke.cmd echo set "SERVER=%SRV%"
:kraj
echo Podesavanje spremljeno.
