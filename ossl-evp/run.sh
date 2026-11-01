#!/bin/bash
# error:0308010C digital envelope routines::unsupported: webpack 4 on Node 16-26, each fix, and Create React App 4.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v) npm $(npm -v) openssl $(node -p process.versions.openssl)"
r() { grep -aE "0308010C|ERR_OSSL|bad option|not allowed|built|Compiled|Failed to compile|ERROR|Error:|hash:|Hash:" | grep -v "^\s*at " | head -${1:-2} | cut -c1-200; echo "   exit ${PIPESTATUS[0]}"; }
mkdir -p wp && cd wp && npm init -y >/dev/null
mkdir -p src && echo 'console.log("hi")' > src/index.js
for V in 4.46.0 4.47.0; do
  npm install -D webpack@$V webpack-cli@3 $Q 2>&1 | tail -1
  echo "-- webpack $V"; npx webpack --mode production 2>&1 | r
done
npm install -D webpack@4.46.0 $Q 2>&1 | tail -1
echo "-- webpack 4.46.0 + NODE_OPTIONS=--openssl-legacy-provider"; NODE_OPTIONS=--openssl-legacy-provider npx webpack --mode production 2>&1 | r
echo "module.exports = { output: { hashFunction: 'sha256' } };" > webpack.config.js
echo "-- webpack 4.46.0 + output.hashFunction sha256"; npx webpack --mode production 2>&1 | r
rm webpack.config.js; cd ..
if [ "${CRA:-0}" = 1 ]; then
  echo "######## Create React App 4 (react-scripts 4.0.3)"
  mkdir -p cra && cd cra && npm init -y >/dev/null
  npm install react@17 react-dom@17 react-scripts@4.0.3 $Q 2>&1 | tail -1
  mkdir -p src public; echo '<div id="root"></div>' > public/index.html
  echo 'import React from "react"; import ReactDOM from "react-dom"; ReactDOM.render(<h1>hi</h1>, document.getElementById("root"));' > src/index.js
  echo "webpack in tree: $(npm ls webpack 2>/dev/null | grep -o 'webpack@[0-9.]*' | sort -u | tr '\n' ' ')"
  echo "-- react-scripts build"; npx react-scripts build 2>&1 | r 3
  echo "-- react-scripts build + --openssl-legacy-provider"; NODE_OPTIONS=--openssl-legacy-provider npx react-scripts build 2>&1 | r 3
  node -e 'const p=require("./package.json"); p.overrides={"webpack":"4.47.0"}; require("fs").writeFileSync("package.json", JSON.stringify(p,null,2))'
  rm -rf node_modules package-lock.json; npm install $Q 2>&1 | tail -1
  echo "webpack in tree: $(npm ls webpack 2>/dev/null | grep -o 'webpack@[0-9.]*' | sort -u | tr '\n' ' ')"
  echo "-- react-scripts build with overrides webpack 4.47.0"; npx react-scripts build > ov.log 2>&1; echo "   exit $?"; grep -v "^s*at " ov.log | grep -v "^s*$" | tail -8 | cut -c1-200
  grep -m1 -A3 "The react-scripts package provided by Create React App requires" ov.log | cut -c1-200
  echo "-- same, SKIP_PREFLIGHT_CHECK=true"; SKIP_PREFLIGHT_CHECK=true npx react-scripts build 2>&1 | r 3
  cd ..
fi
if [ "${CRA:-0}" = 1 ]; then
  echo "######## react-scripts 5.0.1"; mkdir -p cra5 && cd cra5 && npm init -y >/dev/null
  npm pkg delete type  # a real CRA app has no "type"; npm 11 init adds "commonjs", which webpack 5 obeys
  npm install react@18 react-dom@18 react-scripts@5.0.1 $Q 2>&1 | tail -1; cp -r ../cra/src ../cra/public .
  echo "webpack in tree: $(npm ls webpack 2>/dev/null | grep -o "webpack@[0-9.]*" | sort -u | tr '
' ' ')"
  echo "-- react-scripts 5 build"; npx react-scripts build > b5.log 2>&1; echo "   exit $?"; grep -v "^\s*$" b5.log | head -12 | cut -c1-200; cd ..
fi
echo "== done"
