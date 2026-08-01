# Changelog

All notable changes to the `stride-copilot-exploratory-testing` plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Ported from the Claude Code plugin's 2026-07 improvement research: the SFDIPOT correction and an explorer contract that reports what it counted instead of what it could not measure.

### Added

- **`interfaces` lens** — the Heuristic Test Strategy Model's **I**nterfaces element joins the coverage lens in the `chartering` skill, covering APIs, imports and exports, UI surfaces, and integration points between systems: the boundaries where service-oriented and LLM tool-calling applications most often fail. **Downstream consumers must handle `interfaces` as a new allowed value of a charter object's optional `lens` field** (`agents/charter-generator.agent.md`), alongside the existing `structure`, `function`, `data`, `platform`, `operations`, and `time`.

### Changed

- **`SFDPOT` renamed to `SFDIPOT`** across the plugin — skills, agents, fixtures, and docs. Bach's HTSM (v6.0, 2024) lists seven Product Elements; the six-letter `SFDPOT` the plugin cited is a superseded form of the same heuristic. The `Interfaces` row slots between `Data` and `Platform`; no existing row was renamed, reordered, or dropped. The charter object's `source` enum value is still the literal `sfdpot` — it is a wire value, not the acronym, and renaming it would break existing consumers.
- **The `explorer` agent no longer reports numbers it cannot observe.** `session_sheet` drops `duration` and `tbs` (Task Breakdown Metric percentages) — a wall-clock measurement an agent has no way to take, whose presence contradicted the agent's own hard rule against fabricating a result. In their place it reports what it genuinely counts: `probe_budget`, `probes_attempted`, `probes_with_finding`, `on_charter_probes`/`off_charter_probes`, `tool_calls_used`, `heuristics_applied`, and `stop_reason`. An agent session is now bounded by an **agent-native budget** — a probe budget (default 12, band 8–20) and a tool-call ceiling (5 × the probe budget), whichever is reached first. The `session` skill keeps the 60–120 minute box and Task Breakdown Metrics for **human-run and paired** sessions and now states plainly that neither binds an agent session; the four stopping heuristics are unchanged in substance (bullet 2 now reads "The box or the budget is up"). **The `stride-exploratory-testing-explore` skill gains `--probes <count>`** for the per-session probe budget; **`--timebox <minutes>` keeps its unit** and is now documented as doing only what it always effectively did — deciding how many charters run (one session ≈ 90 minutes) — and is never passed to the explorer. **Downstream consumers that read `session_sheet.duration` or `session_sheet.tbs` must switch to the counts**; the `stride-exploratory-testing-debrief` skill is unaffected (it consumes unstructured tagged notes). `fixtures/example-session-sheet.md` and `fixtures/example-debrief.md` are now **agent-run** examples — a `SESSION BUDGET` block with probe and tool-call counts and a `stop_reason` in place of `DURATION` and `TASK BREAKDOWN METRICS`.

## [0.1.0] - 2026-07-21

Initial release: the complete GitHub Copilot CLI port of `cheezy/stride-exploratory-testing`.

### Added

- **Repository and manifest.** Standalone git repository with a root-level `plugin.json` (Copilot schema: root manifest plus `"agents": "agents/"` and `"skills": ["skills/"]`), `README.md`, `HEURISTICS.md`, `LICENSE` (MIT), and this changelog. There is intentionally **no** `commands/` directory — Copilot CLI has no slash commands.
- **Core knowledge skills.** `stride-exploratory-testing` (orchestrator front door), `chartering`, `heuristics`, `oracles`, and `session` — the exploratory-testing doctrine.
- **Command-derived skills.** `stride-exploratory-testing-charter`, `-nightmare-headline`, `-explore`, `-recon`, and `-debrief` — the five upstream slash commands ported as named Copilot skills (Activation-section frontmatter, no `allowed-tools`/`argument-hint`).
- **Agents.** `agents/charter-generator.agent.md` and `agents/explorer.agent.md` (Copilot `.agent.md` format, array-form read-only/`run` tools, no `model` field).
- **Fixtures.** Worked `example-charters.md`, `example-session-sheet.md`, and `example-debrief.md` (synthetic *ExpenseFlow* target) that double as templates and smoke-test regression anchors.
- **Smoke tests.** Cross-platform `lib/test-structure.{sh,ps1}`, `lib/test-frontmatter.{sh,ps1}`, and `lib/test-all.{sh,ps1}` — offline structure/frontmatter validation that gates a release (no network, no `jq`).

### Distribution

- **Vendored into `stride-copilot-marketplace`.** Registered in the existing `cheezy/stride-copilot-marketplace` catalog at `0.1.0` — the plugin tree is vendored under `plugins/stride-copilot-exploratory-testing/` with a matching `plugins[]` entry (`source: ./plugins/stride-copilot-exploratory-testing`), and the catalog `metadata.version` was bumped to `1.6.0`. Once the catalog is registered, install by name with `copilot plugin install stride-copilot-exploratory-testing` (or directly with `copilot plugin install https://github.com/cheezy/stride-copilot-exploratory-testing`; see the README).
