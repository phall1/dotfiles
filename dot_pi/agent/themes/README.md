# Pi Themes

JSON files that define TUI colors. Themes hot-reload when edited.

## Quick Start

Create a `.json` file here with all 51 required color tokens:

```json
{
  "$schema": "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json",
  "name": "my-theme",
  "vars": {
    "primary": "#00aaff",
    "secondary": 242
  },
  "colors": {
    "accent": "primary",
    "border": "primary",
    ...all 51 tokens required...
  }
}
```

## Color Formats

| Format | Example | Description |
|--------|---------|-------------|
| Hex | `"#ff0000"` | 6-digit hex RGB |
| 256-color | `39` | xterm palette index (0-255) |
| Variable | `"primary"` | Reference to `vars` entry |
| Default | `""` | Terminal's default color |

## Required Tokens (51 total)

### Core UI (11)
accent, border, borderAccent, borderMuted, success, error, warning, muted, dim, text, thinkingText

### Backgrounds & Content (11)
selectedBg, userMessageBg, userMessageText, customMessageBg, customMessageText, customMessageLabel,
toolPendingBg, toolSuccessBg, toolErrorBg, toolTitle, toolOutput

### Markdown (10)
mdHeading, mdLink, mdLinkUrl, mdCode, mdCodeBlock, mdCodeBlockBorder,
mdQuote, mdQuoteBorder, mdHr, mdListBullet

### Diffs (3)
toolDiffAdded, toolDiffRemoved, toolDiffContext

### Syntax (9)
syntaxComment, syntaxKeyword, syntaxFunction, syntaxVariable,
syntaxString, syntaxNumber, syntaxType, syntaxOperator, syntaxPunctuation

### Thinking Borders (6)
thinkingOff, thinkingMinimal, thinkingLow, thinkingMedium, thinkingHigh, thinkingXhigh

### Bash Mode (1)
bashMode

## Selecting

Use `/settings` in pi or set `"theme": "my-theme"` in settings.json.

## Reference

- Docs: https://pi.dev/docs/latest/themes
- Built-in themes: dark, light (see pi source for full definitions)
