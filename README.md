# stride-copilot-exploratory-testing

Structured, charter-based **exploratory testing** for the [GitHub Copilot CLI](https://github.com/github/gh-copilot). This is the Copilot port of the Claude Code plugin [`cheezy/stride-exploratory-testing`](https://github.com/cheezy/stride-exploratory-testing): plan charters, run timeboxed sessions, apply named heuristics and oracles, and capture findings — all from Copilot.

> **Status:** `0.1.0` — repository scaffold. Skills and agents are ported in subsequent tasks.

## What this is

Exploratory testing is *testing as a skilled human tester does it* — discovering risks, questions, and bugs that scripted or automated checks miss. The mental model is **Tested = Checked + Explored**. This plugin frames time-boxed sessions and routes each request to the right capability.

Because GitHub Copilot CLI has **no slash commands**, the five commands of the Claude Code plugin (`/charter`, `/nightmare-headline`, `/explore`, `/recon`, `/debrief`) are ported as **named skills** rather than commands. There is intentionally **no `commands/` directory**.

## Installation

This plugin is distributed by vendoring into the existing `stride-copilot-marketplace`. See that repository for installation instructions.

## Layout

| Path | Purpose |
|------|---------|
| `plugin.json` | Root manifest (Copilot schema: root-level manifest plus `agents` and `skills` keys) |
| `skills/` | Ported exploratory-testing skills |
| `agents/` | Ported agents (charter-generator, explorer) |
| `lib/` | Shared helper scripts |
| `fixtures/` | Calibration and test fixtures |

## License

[MIT](LICENSE) © 2026 Jeff Morgan
