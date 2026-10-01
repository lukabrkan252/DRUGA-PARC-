"""Sastavlja MO_planiranje.zip: aplikacija + Excel fajlovi + ugradjeni Windows Python 3.12 sa svim paketima
(korisnik NE instalira nista). Pokretanje: python tools/build_zip.py"""
import glob, io, os, shutil, subprocess, sys, tempfile, urllib.request, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "MO_planiranje.zip")
PY_URL = "https://api.nuget.org/v3-flatcontainer/python/3.12.8/python.3.12.8.nupkg"
TOP = "MO_planiranje/"
APP_FILES = ["app", "assets/icon.ico", "assets/icon.png", "queries", "windows", "data/nalozi.xlsx",
             "data/preostala_norma.xlsx", "requirements.txt", "POCNI_OVDJE.txt"]

tmp = tempfile.mkdtemp()
wheels = os.path.join(tmp, "wheels")
subprocess.check_call([sys.executable, "-m", "pip", "download", "-q", "--dest", wheels, "--only-binary=:all:",
                       "--platform", "win_amd64", "--python-version", "3.12", "--implementation", "cp",
                       "-r", os.path.join(ROOT, "requirements.txt")])
nupkg = io.BytesIO(urllib.request.urlopen(PY_URL).read())

with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
    for item in APP_FILES:
        p = os.path.join(ROOT, item)
        files = [p] if os.path.isfile(p) else [os.path.join(d, f) for d, dn, fn in os.walk(p) for f in fn]
        for f in files:
            if "__pycache__" in f or f.endswith(".pyc"):
                continue
            z.write(f, TOP + os.path.relpath(f, ROOT).replace(os.sep, "/"))
    with zipfile.ZipFile(nupkg) as n:  # Python (tools/ -> python/)
        for name in n.namelist():
            if name.startswith("tools/") and not name.endswith("/") and "/__pycache__/" not in name \
                    and not name.startswith(("tools/libs/", "tools/Lib/test/", "tools/Lib/idlelib/", "tools/Lib/tkinter/", "tools/tcl/")):
                z.writestr(TOP + "python/" + name[len("tools/"):], n.read(name))
    for w in glob.glob(os.path.join(wheels, "*.whl")):  # paketi -> python/Lib/site-packages
        with zipfile.ZipFile(w) as wz:
            for name in wz.namelist():
                if not name.endswith("/"):
                    z.writestr(TOP + "python/Lib/site-packages/" + name, wz.read(name))
shutil.rmtree(tmp)
print(OUT, os.path.getsize(OUT) // 1024 // 1024, "MB")
