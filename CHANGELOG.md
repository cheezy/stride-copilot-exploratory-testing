# Changelog

All notable changes to the `stride-copilot-exploratory-testing` plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-21

### Added

- **Initial repository scaffold.** Standalone git repository for the GitHub Copilot CLI port of `cheezy/stride-exploratory-testing`. Root-level `plugin.json` (Copilot schema: root manifest plus `"agents": "agents/"` and `"skills": ["skills/"]`), the `skills/`, `agents/`, `lib/`, and `fixtures/` directory skeleton (intentionally **no** `commands/` directory — Copilot has no slash commands), `README.md`, `LICENSE` (MIT), and this changelog. Skills and agents are ported in subsequent tasks.
