v=$1
npm i next@$v --no-fund --no-audit >/dev/null 2>&1
echo "===== next@$(node -p "require('next/package.json').version")"
npm audit --json 2>/dev/null > audit.json
node -e "
const a=require('./audit.json'); const n=a.vulnerabilities?.next;
if(!n){console.log('npm audit: next not flagged'); process.exit(0)}
const via=n.via.filter(x=>typeof x==='object');
const sev={}; via.forEach(x=>sev[x.severity]=(sev[x.severity]||0)+1);
console.log('npm audit: next', n.severity, '| advisories:', via.length, JSON.stringify(sev), '| fixAvailable:', JSON.stringify(n.fixAvailable));
"
s=$(date +%s); npx next build > build.log 2>&1; echo "build exit $? in $(( $(date +%s)-s ))s"
grep -iE "secur|vulnerab|upgrade|deprecat|warn|error" build.log | grep -v "^ *$" | head -6 | cut -c1-220
