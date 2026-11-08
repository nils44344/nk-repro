#!/usr/bin/env bash
# Which popular packages still fail with "No module named 'distutils'" on import (8 Nov 2026)?
# Fresh venv per package with NO setuptools (python -m venv on 3.12+ doesn't add it), latest version from PyPI.
# Then the same import with setuptools installed, to see whether the setuptools bridge is enough.
set -u
W=${W:-/tmp/du-pkgs}
PY=${PY:-python3}
# package:import-name
PKGS="undetected-chromedriver:undetected_chromedriver pyautogui:pyautogui pyttsx3:pyttsx3 moviepy:moviepy gym:gym gymnasium:gymnasium nltk:nltk pygame:pygame kivy:kivy selenium:selenium numpy:numpy pandas:pandas matplotlib:matplotlib scipy:scipy opencv-python-headless:cv2 tensorboard:tensorboard torch:torch pyinstaller:PyInstaller cx_Freeze:cx_Freeze imageio:imageio sklearn-crfsuite:sklearn_crfsuite pafy:pafy youtube-dl:youtube_dl yt-dlp:yt_dlp mysqlclient:MySQLdb psycopg2-binary:psycopg2 pycryptodome:Crypto bs4:bs4 lxml:lxml pyqt5:PyQt5 tflearn:tflearn flask:flask django:django fastapi:fastapi"
echo "$($PY -V), $(uname -s), $(date -u +%F)"
printf '%-26s | %-12s | %-48s | %s\n' package version "import without setuptools" "with setuptools"
for e in $PKGS; do
  p=${e%%:*}; m=${e##*:}
  d="$W/$p"; rm -rf "$d"; $PY -m venv "$d"
  if ! "$d/bin/python" -m pip install -q --disable-pip-version-check "$p" >/dev/null 2>"$d.err"; then
    printf '%-26s | %-12s | %s\n' "$p" "-" "install failed: $(grep -m1 -oE "No module named '[^']+'|error: [^.]{0,60}" "$d.err" | head -1)"; continue
  fi
  v=$("$d/bin/python" -m pip show "$p" 2>/dev/null | awk '/^Version/{print $2}')
  st=$("$d/bin/python" -c "import importlib.util as u; print('yes' if u.find_spec('setuptools') else 'no')")
  r1=$(timeout 120 env DISPLAY= "$d/bin/python" -c "import $m" 2>&1 | grep -oE "(ModuleNotFoundError|ImportError|[A-Za-z]+Error): .{0,60}" | tail -1)
  r2="-"
  if echo "$r1" | grep -q distutils; then
    "$d/bin/python" -m pip install -q --disable-pip-version-check setuptools >/dev/null 2>&1
    r2=$(timeout 120 env DISPLAY= "$d/bin/python" -c "import $m" 2>&1 | grep -oE "(ModuleNotFoundError|ImportError|[A-Za-z]+Error): .{0,60}" | tail -1)
    r2=${r2:-imports OK}
  fi
  printf '%-26s | %-12s | %-48s | %s\n' "$p" "$v" "${r1:-imports OK} (setuptools present: $st)" "$r2"
  rm -rf "$d"
done
