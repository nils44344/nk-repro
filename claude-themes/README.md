# Claude Code themes (30 originals)

Custom colour themes for the Claude Code terminal CLI, in the format from the official docs
(https://code.claude.com/docs/en/terminal-config.md#create-a-custom-theme): one JSON file per theme in `~/.claude/themes/`, fields `name`, `base`, `overrides`.
Each theme sets 24 tokens. Gallery with previews, copy and download buttons: https://nilaykabariya.blog/claude-code-themes

Unofficial and not affiliated with Anthropic.

## Install

The folder may not exist yet, and a first-time install needs one restart of Claude Code.

```bash
mkdir -p ~/.claude/themes && cp themes/*.json ~/.claude/themes/
```

Then run `/theme` inside Claude Code and pick one. New files in the folder show up without another restart.

## The themes

| Theme | Base | Collection | Mood | Text / lowest readable contrast | Idea |
|---|---|---|---|---|---|
| Chai at Midnight | dark | Places and hours | Warm, Calm, Dark | 15.3:1 / 6.2:1 | Warm amber on cocoa, the colour of the last chai. |
| Monsoon, Surat | dark | Places and hours | Cool, Calm, Dark | 15.0:1 / 6.6:1 | Rain-washed teals for long debugging evenings in Surat. |
| Paper Lantern | light | Festivals | Warm, Soft, Light | 14.5:1 / 4.5:1 | Cream paper and a vermilion lantern: a light theme that does not burn your eyes. |
| Terminal Mango | dark | Machines and arcades | Bold, Warm, Dark | 17.0:1 / 6.3:1 | Hot mango on near-black: loud accent, quiet everything else. |
| Kite Festival | light | Festivals | Playful, Bold, Light | 16.3:1 / 4.7:1 | Magenta, cyan and violet against a bright Uttarayan sky. |
| Rasgulla at Dawn | light | Places and hours | Soft, Warm, Light | 12.8:1 / 4.5:1 | Syrup gold, rose water and cream: a sweet shop opening at first light. |
| Lavender Field, 5 pm | light | Places and hours | Soft, Calm, Cool, Light | 12.9:1 / 4.5:1 | Pastel lilac with sage and dusk-blue: long shadows over a field, nothing shouting. |
| Candy Floss Arcade | light | Machines and arcades | Playful, Bold, Light | 14.5:1 / 4.5:1 | Spun sugar pink and bubble-gum blue on a fairground-bright white. |
| Jewel Box | dark | Materials | Bold, Cool, Dark | 15.1:1 / 5.3:1 | Emerald velvet lining with ruby, sapphire, amber and amethyst set into it. |
| Rose Quartz Notebook | light | Materials | Soft, Calm, Light | 12.4:1 / 4.5:1 | A stone-pink paper notebook with a dark-plum pen and one gold-edged page. |
| Neon Rickshaw | dark | Machines and arcades | Bold, Playful, Dark | 18.2:1 / 5.8:1 | A night-market auto rickshaw wired with tube lights, magenta first. |
| Steel Mill, 4 am | dark | Places and hours | Cool, Calm, Dark | 13.5:1 / 6.5:1 | Cold rolled steel greys in the dark, and sparks of orange where metal meets metal. |
| Pit Lane | dark | Machines and arcades | Bold, Dark | 17.4:1 / 4.5:1 | Tarmac black, race-flag red and signal yellow: everything reads at a glance at speed. |
| Bandhani Night | dark | Textiles | Warm, Playful, Dark | 14.7:1 / 6.2:1 | Tie-dyed indigo cloth: dye-red and saffron dots on a deep night-blue ground. |
| Sakura Night | dark | Places and hours | Soft, Calm, Dark | 14.8:1 / 7.5:1 | Blossom pink falling on a plum-dark evening. |
| Sea Glass, Noon | light | Day and night | Cool, Calm, Light | 12.3:1 / 4.6:1 | Daylight through a green glass bottle on a windowsill. The daytime half of a pair. |
| Sea Glass, Midnight | dark | Day and night | Cool, Calm, Dark | 14.9:1 / 7.4:1 | The same bottle by moonlight. The night half of the pair, same hues, same roles. |
| Diwali Diya | dark | Festivals | Warm, Bold, Dark | 15.9:1 / 6.5:1 | A row of clay lamps in a dark maroon room: flame yellow, saffron and ember. |
| Holi Morning | light | Festivals | Playful, Bold, Light | 15.9:1 / 4.5:1 | Powder colours thrown on a white morning: magenta, teal, blue and orange all at once. |
| Low-Glare Night | dark | Made for a need | Calm, Warm, Dark | 10.4:1 / 5.8:1 | Made for late hours: warm browns and muted tones with almost no blue light, so the screen does not glare. |
| High-Contrast Chalk | dark | Made for a need | Bold, Dark | 21.0:1 / 7.1:1 | Pure black and white with bright chalk colours: every readable colour is at least 7:1. |
| Safe Signals | dark | Made for a need | Calm, Cool, Dark | 15.5:1 / 5.8:1 | Built on the Okabe-Ito colour-blind-safe palette: success, error and warning stay apart under red-green colour blindness, and added and removed lines are blue and orange. |
| Aurora Night Train | dark | Places and hours | Cool, Playful, Dark | 16.2:1 / 7.0:1 | A night train through the north: green and violet light over deep blue. |
| Cricket Pitch | light | Games | Playful, Bold, Light | 13.3:1 / 4.5:1 | Mown-grass cream, ball red and whites: a Sunday match. |
| Gulmohar Summer | light | Places and hours | Bold, Warm, Light | 14.8:1 / 4.5:1 | Gulmohar blossom, orange-red over a hot white afternoon. |
| Ink and Indigo | light | Textiles | Cool, Calm, Light | 13.5:1 / 4.6:1 | Block-printed indigo on unbleached cotton. |
| Marble and Brass | light | Materials | Calm, Cool, Light | 13.6:1 / 4.6:1 | Cool grey marble with a brass accent: a quiet, formal light theme. |
| Mehendi Green | dark | Festivals | Warm, Calm, Dark | 13.4:1 / 5.2:1 | Fresh henna paste green, drying to terracotta. |
| Mogra Evening | light | Places and hours | Soft, Calm, Light | 11.5:1 / 4.6:1 | Jasmine white and leaf green on a warm evening veranda. |
| Old Radio | dark | Machines and arcades | Warm, Calm, Dark | 13.1:1 / 5.7:1 | A walnut cabinet, a glowing amber dial and cloth-speaker beige. |

## How they are made and checked

- `build_themes.py` derives the newer themes (everything after the first five) from a compact palette spec (background, text, accent and six status/mode colours), fitting every readable colour to its contrast target. The first five are hand-written JSON.
- `validate.py` checks every theme and writes `checks.json`: only documented tokens and `#rrggbb` colours; WCAG contrast of every readable token against the design background (a theme cannot set the terminal's own background); text readable on the added/removed diff lines; success, error and warning clearly different (CIE76 delta-E); added vs removed backgrounds different; and the same colour distance after simulating deuteranopia and protanopia. Only `safe-signals` is built and claimed to pass the colour-blind check; for the others it is reported, not claimed.
- Listed in the real `/theme` picker: all 30 on Claude Code 2.1.325 (throwaway config folder via `CLAUDE_CONFIG_DIR`; counted: 7 built-ins + 30 custom + "New custom theme…"), and the first five on 2.1.319 on the owner's own terminal.
- Not checked: screenshots of each palette in a live session. The gallery previews are drawn from the theme colours.

Themes are grouped by mood and colour family only.
