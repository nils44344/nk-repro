# Next.js security versions: does npm audit flag them, and does the build still pass?

Code behind [Next.js 16.3 vulnerabilities: which version is patched?](https://nilaykabariya.blog/tested/nextjs-16-3-vulnerabilities-which-version-is-patched). It is a small Next.js app (`app/`, `middleware.ts`, `public/`) used as a test subject. `check.sh` installs one Next.js version into it, then prints two things:

1. what `npm audit` says about `next` for that version (not flagged, or the severity and the number of advisories);
2. whether `next build` still passes, how long it took, and the first lines of the build log that mention security, upgrades, deprecation, warnings or errors.

Run it with one version per call:

```bash
npm install
bash check.sh 16.4.4
bash check.sh 16.4.5
bash check.sh 16.4.6
bash check.sh 15.5.29
```

`npm audit` needs network access to the npm advisory service, so results change when new advisories are published. The post states the date it was last checked, and the GitHub Actions run of the `next-security` workflow in this repo reproduces the table on a clean runner.
