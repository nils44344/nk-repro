// Load SWC's native addons the way Docusaurus does, and print the real error if it fails.
for (const pkg of ['@swc/html', '@swc/core']) {
  try { require(pkg); console.log(`${pkg} ${require(`${pkg}/package.json`).version}: loaded`); }
  catch (e) {
    const causes = [].concat(e.cause ?? []).map((c) => String(c.message ?? c).split('\n')[0]);
    console.log(`${pkg}: FAILED ${e.message}`);
    for (const c of causes) console.log(`  cause: ${c.slice(0, 400)}`);
  }
}
