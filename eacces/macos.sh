#!/usr/bin/env bash
# npm install -g on macOS (8 Nov 2026): does it hit EACCES with the nodejs.org installer, Homebrew, or nvm?
# GitHub's macos-latest runner, user "runner" (not root). Each case uses its own node binary by full path.
set -u
# The runner presets an npm prefix (env / ~/.npmrc). Clear it so each case uses the install's own defaults.
env | grep -i "npm_config" | sed 's/=.*/=<set>/' || true
unset NPM_CONFIG_PREFIX npm_config_prefix
export NPM_CONFIG_USERCONFIG=/tmp/empty-npmrc; : > /tmp/empty-npmrc
NODE_V=${NODE_V:-24.15.0}
echo "macOS $(sw_vers -productVersion) $(uname -m), user $(whoami), $(date -u +%F)"

echo; echo "=== 1. nodejs.org .pkg installer (installs into /usr/local) ==="
curl -sfLo /tmp/node.pkg "https://nodejs.org/dist/v$NODE_V/node-v$NODE_V.pkg"
sudo installer -pkg /tmp/node.pkg -target / >/dev/null
ls -ld /usr/local/lib/node_modules
/usr/local/bin/npm -v
/usr/local/bin/npm config get prefix
/usr/local/bin/npm install -g cowsay 2>&1 | grep -E "^npm error (code|syscall|path|errno)|added" | head -6
echo "--- fix A: a prefix of your own"
mkdir -p ~/.npm-global && /usr/local/bin/npm config set prefix ~/.npm-global && cat /tmp/empty-npmrc
/usr/local/bin/npm install -g cowsay 2>&1 | grep -E "^npm error code|added" | head -2
ls ~/.npm-global/bin/cowsay && echo "PATH needs: ~/.npm-global/bin"
/usr/local/bin/npm config delete prefix

echo; echo "=== 2. sudo npm install -g, then a normal npm install ==="
sudo /usr/local/bin/npm install -g cowsay 2>&1 | grep -E "^npm error code|added" | head -2
echo "owner of ~/.npm after sudo:"; ls -ld ~/.npm; find ~/.npm -maxdepth 2 -user root | head -3
mkdir -p /tmp/proj && cd /tmp/proj && /usr/local/bin/npm init -y >/dev/null
/usr/local/bin/npm install is-number 2>&1 | grep -E "^npm error (code|syscall|path)|root-owned|added" | head -5
cd /

echo; echo "=== 3. Homebrew node ==="
brew install node >/dev/null 2>&1
B=$(brew --prefix)/bin
ls -ld "$(brew --prefix)/lib/node_modules"
"$B/node" -v; "$B/npm" config get prefix
"$B/npm" install -g cowsay 2>&1 | grep -E "^npm error code|added" | head -2

echo; echo "=== 4. nvm ==="
export NVM_DIR=$HOME/.nvm-test && mkdir -p $NVM_DIR
curl -sfo- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash >/dev/null 2>&1
. $NVM_DIR/nvm.sh && nvm install $NODE_V >/dev/null 2>&1 && npm config get prefix && npm install -g cowsay 2>&1 | grep -E "^npm error code|added" | head -2
