#!/bin/bash
# "Failed building wheel for PyYAML": Windows 11, no Visual C++ build tools, 30 Oct 2026
export SSL_CERT_FILE=D:/tools/ca-bundle-win.pem REQUESTS_CA_BUNDLE=D:/tools/ca-bundle-win.pem PIP_DISABLE_PIP_VERSION_CHECK=1
P315=D:/py315n/tools/python.exe; P314=C:/Users/NIR/AppData/Local/Python/pythoncore-3.14-64/python.exe
v() { rm -rf "D:/nk-pyyaml/$1"; "$2" -m venv "D:/nk-pyyaml/$1"; echo "D:/nk-pyyaml/$1/Scripts/python.exe"; }
key() { grep -E "error|Error|ERROR|note:|Successfully|Building wheel|Using cached|Downloading|cython_sources|WARNING|×|╰" | grep -v "^\s*$" | head -${1:-14}; }
echo "== 1. Python 3.15.2: pip install pyyaml"; py=$(v a $P315); $py -m pip --version; $py -m pip install pyyaml 2>&1 | key 18
echo "== 2. 3.15: PYYAML_FORCE_LIBYAML=0"; py=$(v b $P315); PYYAML_FORCE_LIBYAML=0 $py -m pip install pyyaml 2>&1 | key; $py -c "import yaml;print('yaml', yaml.__version__, 'libyaml C:', yaml.__with_libyaml__)" 2>&1 | tail -1
echo "== 3. 3.15: --only-binary"; py=$(v c $P315); $py -m pip install --only-binary=:all: pyyaml 2>&1 | key 4
echo "== 4. 3.14: pip install pyyaml"; py=$(v d $P314); $py -m pip install pyyaml 2>&1 | key 4; $py -c "import yaml;print('yaml', yaml.__version__, yaml.__with_libyaml__)"
echo "== 5. 3.14: pyyaml==5.4.1"; py=$(v e $P314); $py -m pip install pyyaml==5.4.1 2>&1 | key 16
echo "== 6. 3.14: 5.4.1 with cython<3 + --no-build-isolation"; py=$(v f $P314); $py -m pip install "cython<3" setuptools wheel 2>&1 | key 3; $py -m pip install --no-build-isolation pyyaml==5.4.1 2>&1 | key 10
echo "== 7. 3.14: pyyaml==6.0.1"; py=$(v g $P314); $py -m pip install pyyaml==6.0.1 2>&1 | key 8
