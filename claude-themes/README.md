# Claude Code themes (five originals)

Custom colour themes for the Claude Code terminal CLI, written to the format in the official docs
(https://code.claude.com/docs/en/terminal-config.md#create-a-custom-theme): one JSON file per theme in `~/.claude/themes/`,
fields `name`, `base`, `overrides`. Each theme sets 24 tokens (accent, text, status colours, diff colours, message background, selection, usage meter).

| Theme | Base | Mood |
|---|---|---|
| Chai at Midnight | dark | warm amber on cocoa, a late-night terminal |
| Monsoon, Surat | dark | rain-washed teals |
| Paper Lantern | light | cream paper, vermilion accent |
| Terminal Mango | dark | hot mango on near-black |
| Kite Festival | light | magenta, cyan and violet on white (Uttarayan) |

## Install

```bash
mkdir -p ~/.claude/themes && cp themes/*.json ~/.claude/themes/
```

Then run `/theme` inside Claude Code and pick one. If `~/.claude/themes/` did not exist before, restart Claude Code once.

## What was checked

`python validate.py` (this folder) checks every theme against the documented token list, accepts only `#rrggbb` colours and
measures WCAG contrast of the readable tokens (text, accent, status colours) against a nominal terminal background
(`nominal-backgrounds.json`). A Claude Code theme cannot set the terminal's own background, so these are the backgrounds the
palettes were designed for. All five pass: no unknown tokens, no invalid colours, every readable token at 4.5:1 or better.

**Also checked:** all 24 tokens the themes use appear as strings inside the installed Claude Code 2.1.319 binary (`grep -a` over the executable), so
that version knows every token. Documented version note: custom themes need a recent Claude Code; the docs do not state the minimum version.

**Not yet checked:** opening `/theme` in a real terminal and looking at the five themes on screen. Until that is done, the previews are
mock-ups of how the tokens map, not screenshots.
