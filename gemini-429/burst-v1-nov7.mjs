// SDK 3.0.0 (default API v1): fire requests until a per-minute 429, then check the body the 429 post's helper parses (7 Nov 2026).
const { GoogleGenAI, ApiError } = await import('genai3');
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
for (let i = 1; i <= 40; i++) {
  try { await ai.models.generateContent({ model: 'gemini-3.5-flash-lite', contents: 'hi', config: { maxOutputTokens: 1 } }); }
  catch (e) {
    if (!(e instanceof ApiError)) { console.log('non-ApiError', String(e).slice(0, 120)); break; }
    if (e.status !== 429) { console.log(`#${i} status ${e.status}`); continue; }
    const body = JSON.parse(e.message).error;
    const delay = body.details?.find((d) => d['@type']?.endsWith('RetryInfo'))?.retryDelay;
    console.log(`#${i} 429 ApiError | status ${body.status} | RetryInfo.retryDelay=${delay} | limit: ${(body.message.match(/limit: \d+/) || ['?'])[0]} | details: ${body.details.map((d) => d['@type'].split('.').pop()).join(',')}`);
    break;
  }
  if (i === 40) console.log('no 429 in 40 calls');
}
