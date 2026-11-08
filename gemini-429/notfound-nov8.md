# "models/X is not found for API version v1beta / v1" (8 Nov 2026)

Windows 11, Node 24.14.0, a new free-tier AI Studio key. Run with `GEMINI_API_KEY=... node <script>`; the key is never printed.

- `notfound-nov8.mjs` -> `notfound-nov8.txt`: the generateContent models ListModels returns on v1 and on v1beta, then 13 common model names called on both versions over REST.
- `notfound-fix-nov8.mjs` -> `notfound-fix-nov8.txt`: names from the list on each version, and the URL @google/genai 2.27.0 and 3.0.0 call by default.
