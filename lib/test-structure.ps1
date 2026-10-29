# PowerShell mirror of test-structure.sh — structure smoke test for the
# stride-copilot-exploratory-testing plugin.
#
# Asserts the plugin ships every file the Copilot plugin schema and this
# plugin's docs require: a valid ROOT manifest, all six core knowledge
# skills, all seven command-derived skills, both .agent.md agents, the three
# README-referenced fixtures, and the root docs. Then pins content: the
# explorer card in agents/explorer.agent.md (markers, position, 4,096-byte
# cap, severity tokens against bug-advocacy's four levels, stop_reason values
# against the output contract, and path-free skill references). No network,
# no jq (JSON via ConvertFrom-Json).
#
# Copilot conventions: plugin.json at the repository ROOT, agents use the
# .agent.md extension, and there is NO commands/ directory.
#
# Exit code: 0 if every check passes; 1 if any check fails.

Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot = Split-Path -Parent $ScriptDir

$script:PASS = 0
$script:FAIL = 0
function Pass($m) { $script:PASS++; Write-Host "  PASS  $m" }
function Fail($m, $d = '') { $script:FAIL++; Write-Host "  FAIL  $m"; if ($d) { Write-Host "        $d" } }

Write-Host 'stride-copilot-exploratory-testing structure smoke test'
Write-Host "plugin root: $PluginRoot"
Write-Host ''

# --- Manifest (ROOT plugin.json) -------------------------------------------

$Manifest = Join-Path $PluginRoot 'plugin.json'
if (Test-Path -LiteralPath $Manifest -PathType Leaf) {
    try {
        $json = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
        Pass 'plugin.json exists at the root and is valid JSON'
        $required = @('name', 'description', 'version', 'agents', 'skills')
        $missing = @($required | Where-Object { -not ($json.PSObject.Properties.Name -contains $_) })
        if ($missing.Count -eq 0) {
            Pass 'plugin.json has the required keys (name, description, version, agents, skills)'
        }
        else {
            Fail 'plugin.json is missing required key(s)' ($missing -join ', ')
        }
    }
    catch {
        Fail 'plugin.json is not valid JSON' $_.Exception.Message
    }
}
else {
    Fail 'plugin.json not found at the plugin root' $Manifest
}

# --- Core knowledge skills -------------------------------------------------

foreach ($skill in @('stride-exploratory-testing', 'chartering', 'heuristics', 'oracles', 'bug-advocacy', 'session')) {
    $p = Join-Path $PluginRoot "skills/$skill/SKILL.md"
    if (Test-Path -LiteralPath $p -PathType Leaf) { Pass "skills/$skill/SKILL.md exists" }
    else { Fail "skills/$skill/SKILL.md is missing" }
}

# --- Command-derived skills (replace the upstream slash commands) -----------

foreach ($skill in @(
        'stride-exploratory-testing-charter',
        'stride-exploratory-testing-nightmare-headline',
        'stride-exploratory-testing-explore',
        'stride-exploratory-testing-recon',
        'stride-exploratory-testing-debrief',
        'stride-exploratory-testing-pair',
        'stride-exploratory-testing-harden')) {
    $p = Join-Path $PluginRoot "skills/$skill/SKILL.md"
    if (Test-Path -LiteralPath $p -PathType Leaf) { Pass "skills/$skill/SKILL.md exists" }
    else { Fail "skills/$skill/SKILL.md is missing" }
}

# Count only real SKILL.md files (any .gitkeep placeholder is ignored).
$skillCount = @(Get-ChildItem -LiteralPath (Join-Path $PluginRoot 'skills') -Directory |
    ForEach-Object { Join-Path $_.FullName 'SKILL.md' } |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }).Count
if ($skillCount -eq 13) {
    Pass 'exactly 13 SKILL.md files present (6 core + 7 command-derived; .gitkeep ignored)'
}
else {
    Fail "expected 13 SKILL.md files, found $skillCount"
}

# --- Agents (.agent.md extension) ------------------------------------------

foreach ($agent in @('charter-generator', 'explorer')) {
    $p = Join-Path $PluginRoot "agents/$agent.agent.md"
    if (Test-Path -LiteralPath $p -PathType Leaf) { Pass "agents/$agent.agent.md exists" }
    else { Fail "agents/$agent.agent.md is missing" }
}

# Count only *.agent.md files (any .gitkeep placeholder is ignored).
$agentCount = @(Get-ChildItem -LiteralPath (Join-Path $PluginRoot 'agents') -Filter '*.agent.md' -File).Count
if ($agentCount -eq 2) {
    Pass 'exactly 2 agent files present (.gitkeep ignored)'
}
else {
    Fail "expected 2 agent files, found $agentCount"
}

# --- Fixtures (referenced by README.md) ------------------------------------

foreach ($fixture in @('example-charters.md', 'example-session-sheet.md', 'example-debrief.md')) {
    $p = Join-Path $PluginRoot "fixtures/$fixture"
    if (Test-Path -LiteralPath $p -PathType Leaf) { Pass "fixtures/$fixture exists" }
    else { Fail "fixtures/$fixture is missing" }
}

# --- Root docs -------------------------------------------------------------

foreach ($doc in @('README.md', 'CHANGELOG.md', 'LICENSE')) {
    $p = Join-Path $PluginRoot $doc
    if (Test-Path -LiteralPath $p -PathType Leaf) { Pass "$doc exists" }
    else { Fail "$doc is missing" }
}

# --- Content pins: explorer card -------------------------------------------
#
# The first content pins in this edition, mirroring test-structure.sh with
# the same labels. Every rule the explorer needs to label a bug and end a
# session lives on an inline card in agents/explorer.agent.md, so nothing
# depends on a skill load succeeding. These pins keep the card in place and
# under its 4,096-byte cap, keep its severity tokens in step with
# bug-advocacy's four levels and its stop rules in step with the output
# contract's stop_reason values, and keep the optional skill references free
# of file paths. Later port tasks add their pins to this section. Read-only:
# the files are read as text, never run.

function Read-Lines([string]$path) {
    # Split on LF only and keep any CR, so byte counts match awk | wc -c.
    $parts = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) -split "`n"
    $list = New-Object 'System.Collections.Generic.List[string]'
    foreach ($p in $parts) { $list.Add($p) }
    if ($list.Count -gt 0 -and $list[$list.Count - 1] -eq '') { $list.RemoveAt($list.Count - 1) }
    return ,$list
}

function Get-Ticked([string]$text, [string]$pattern) {
    $out = New-Object 'System.Collections.Generic.List[string]'
    foreach ($m in [regex]::Matches($text, $pattern)) { $out.Add($m.Groups[1].Value) }
    return ,$out
}

Write-Host ''
$Explorer = Join-Path $PluginRoot 'agents/explorer.agent.md'
$Advocacy = Join-Path $PluginRoot 'skills/bug-advocacy/SKILL.md'

if ((Test-Path -LiteralPath $Explorer -PathType Leaf) -and (Test-Path -LiteralPath $Advocacy -PathType Leaf)) {
    $exLines  = Read-Lines $Explorer
    $advLines = Read-Lines $Advocacy

    # Markers: exactly one of each, start before end, each alone on its line.
    $mStart = 0; $mEnd = 0; $lStart = 0; $lEnd = 0; $exact = $true
    for ($i = 0; $i -lt $exLines.Count; $i++) {
        $line = $exLines[$i].TrimEnd([char]13)
        if ($line.Contains('explorer-card:start')) {
            $mStart++; if ($lStart -eq 0) { $lStart = $i + 1 }
            if ($line -cne '<!-- explorer-card:start -->') { $exact = $false }
        }
        if ($line.Contains('explorer-card:end')) {
            $mEnd++; if ($lEnd -eq 0) { $lEnd = $i + 1 }
            if ($line -cne '<!-- explorer-card:end -->') { $exact = $false }
        }
    }
    $cardOk = ($mStart -eq 1 -and $mEnd -eq 1 -and $lStart -lt $lEnd -and $exact)
    if ($cardOk) {
        Pass 'explorer card has exactly one start and one end marker, in order'
    }
    else {
        Fail 'explorer card markers are invalid' "start=$mStart end=$mEnd; need exactly one of each, start before end, each alone on its line"
    }

    $card = New-Object 'System.Collections.Generic.List[string]'
    if ($cardOk) { for ($i = $lStart - 1; $i -le $lEnd - 1; $i++) { $card.Add($exLines[$i]) } }
    $cardTrim = New-Object 'System.Collections.Generic.List[string]'
    foreach ($l in $card) { $cardTrim.Add($l.TrimEnd([char]13)) }

    # Position: the card is the first section after the safety boundary.
    $heads = New-Object 'System.Collections.Generic.List[object]'
    for ($i = 0; $i -lt $exLines.Count -and $heads.Count -lt 3; $i++) {
        $line = $exLines[$i].TrimEnd([char]13)
        if ($line.StartsWith('## ', [StringComparison]::Ordinal)) { $heads.Add(@(($i + 1), $line)) }
    }
    $posOk = $cardOk -and $heads.Count -eq 3 `
        -and $heads[0][1].StartsWith('## Safety boundary', [StringComparison]::Ordinal) `
        -and $heads[1][1].StartsWith('## Explorer card', [StringComparison]::Ordinal) `
        -and $heads[1][0] -eq ($lStart + 1) -and $lEnd -lt $heads[2][0]
    if ($posOk) {
        Pass 'explorer card sits right after the safety boundary'
    }
    else {
        Fail 'explorer card is not the first section after the safety boundary' "need '## Safety boundary', then the start marker with '## Explorer card' on the next line, then the end marker before the next section"
    }

    # Byte cap, measured as awk '/explorer-card:start/,/explorer-card:end/' | wc -c
    $cardBytes = 0
    foreach ($l in $card) { $cardBytes += [Text.Encoding]::UTF8.GetByteCount($l) + 1 }
    if ($cardBytes -ge 1 -and $cardBytes -le 4096) {
        Pass 'explorer card is within 4096 bytes'
    }
    else {
        Fail 'explorer card is outside 1-4096 bytes' "measured $cardBytes bytes"
    }

    # Severity: token line, rank line and ladder bullets each equal
    # bug-advocacy's four-levels table, in order.
    $table = New-Object 'System.Collections.Generic.List[string]'
    $inTable = $false
    $rank = ''
    foreach ($raw in $advLines) {
        $line = $raw.TrimEnd([char]13)
        if ($line.StartsWith('### The four levels', [StringComparison]::Ordinal)) { $inTable = $true; continue }
        if ($line.StartsWith('### ', [StringComparison]::Ordinal)) { $inTable = $false }
        if ($inTable) {
            $m = [regex]::Match($line, '^\| \*\*([A-Za-z]+)\*\* \|')
            if ($m.Success) { $table.Add($m.Groups[1].Value) }
        }
        if ($rank -eq '') {
            $m = [regex]::Match($line, 'Rank order is \*\*([A-Za-z >]+)\*\*')
            if ($m.Success) { $rank = ($m.Groups[1].Value -split ' > ') -join ' ' }
        }
    }
    $tableStr = $table -join ' '
    $cEnum = ''; $cRank = ''
    $ladder = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in $cardTrim) {
        if ($line.StartsWith('Severity tokens: ', [StringComparison]::Ordinal) -and $cEnum -eq '') {
            $cEnum = (Get-Ticked $line '`([A-Za-z]+)`') -join ' '
        }
        if ($line.StartsWith('Severity rank: ', [StringComparison]::Ordinal) -and $cRank -eq '') {
            $cRank = ($line.Substring(15) -split ' > ') -join ' '
        }
        $m = [regex]::Match($line, '^- \*\*([A-Za-z]+)\*\*: ')
        if ($m.Success) { $ladder.Add($m.Groups[1].Value) }
    }
    $cLadder = $ladder -join ' '
    if ($table.Count -eq 4 -and $rank -ceq $tableStr -and $cEnum -ceq $tableStr -and $cRank -ceq $tableStr -and $cLadder -ceq $tableStr) {
        Pass "explorer card severity tokens, rank and ladder match bug-advocacy's four levels"
    }
    else {
        Fail 'explorer card severity drifted from bug-advocacy' "table='$tableStr' rank='$rank' card tokens='$cEnum' card rank='$cRank' card ladder='$cLadder'"
    }

    # stop_reason: the card's stop values and the output contract's must be the same set.
    $cStops = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($line in $cardTrim) {
        $m = [regex]::Match($line, '^- `([a-z_]+)`: ')
        if ($m.Success) { [void]$cStops.Add($m.Groups[1].Value) }
    }
    $kStops = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $rowPrefix = '| `stop_reason` |'
    foreach ($raw in $exLines) {
        $line = $raw.TrimEnd([char]13)
        if ($line.StartsWith($rowPrefix, [StringComparison]::Ordinal)) {
            foreach ($v in (Get-Ticked $line.Substring($rowPrefix.Length) '`([a-z_]+)`')) { [void]$kStops.Add($v) }
        }
    }
    if ($cStops.Count -gt 0 -and $cStops.SetEquals($kStops)) {
        Pass "explorer card stop rules name exactly the output contract's stop_reason values"
    }
    else {
        $onlyCard = @($cStops | Where-Object { -not $kStops.Contains($_) } | Sort-Object) -join ' '
        $onlyContract = @($kStops | Where-Object { -not $cStops.Contains($_) } | Sort-Object) -join ' '
        Fail 'explorer card stop_reason values differ from the output contract' "in card only: [$onlyCard] in contract only: [$onlyContract]"
    }

    # RIMGEA mapped onto bugs[] fields, and the three oracle verdicts.
    $cardText = $cardTrim -join "`n"
    $missingMap = ''
    foreach ($needle in @('- Replicate:', '- Isolate fills `minimal_repro`:', '- Maximize fills `worst_observed`:',
                          '- Generalize fills `generalization`:', '- Externalize fills `stakeholder_impact`:',
                          '- And say it clearly:', 'Verdicts: Defect; Known-bad-but-expected (', '); Acceptable.')) {
        if (-not $cardText.Contains($needle)) { $missingMap += " [$needle]" }
    }
    if ($missingMap -eq '') {
        Pass 'explorer card maps RIMGEA onto bugs[] fields and names the oracle verdicts'
    }
    else {
        Fail 'explorer card is missing RIMGEA or oracle-verdict text' "missing:$missingMap"
    }

    # The tie rule, the three modifiers and their combination rule, the
    # likelihood rule, the unknown-impact rule, and the three oracle kinds.
    $missingRules = ''
    foreach ($needle in @('Tie rule: when clauses at two levels match, use the higher one, and only if you demonstrated it.',
                          'Reach (', 'Avoidability (', 'Persistence (', 'One alone moves nothing',
                          'two or more raise the level by exactly one', 'never produce Critical', 'Minor is the floor',
                          'Likelihood is not a severity input', 'never Critical or High',
                          'start `stakeholder_impact` with "Provisional"',
                          'Kinds, tried in this order: Never/Always invariants (', '); consistency oracles (', '); approximations (')) {
        if (-not $cardText.Contains($needle)) { $missingRules += " [$needle]" }
    }
    if ($missingRules -eq '') {
        Pass 'explorer card carries the tie, modifier, likelihood and unknown-impact rules and the three oracle kinds'
    }
    else {
        Fail 'explorer card is missing severity or oracle rule text' "missing:$missingRules"
    }

    # Skill references. Copilot documents no path form by which an agent body
    # reaches a plugin skill file (${PLUGIN_ROOT} expands only in an agent's
    # mcp-servers frontmatter); it picks a skill by name and description. So a
    # bare skills/<name>/SKILL.md path is refused and each skill is named.
    $relRefs = 0
    foreach ($raw in $exLines) {
        if ([regex]::IsMatch($raw, 'skills/[a-z-]+/SKILL\.md')) { $relRefs++ }
    }
    if ($relRefs -eq 0) {
        Pass 'agents/explorer.agent.md names no skill by a skills/<name>/SKILL.md path'
    }
    else {
        Fail 'agents/explorer.agent.md names a skill by a skills/<name>/SKILL.md path' "$relRefs line(s); name the skill instead, since Copilot documents no path form for an agent to reach a plugin skill"
    }

    $missingByName = ''
    foreach ($skill in @('heuristics', 'oracles', 'bug-advocacy', 'session')) {
        $pat = '- **`' + $skill + '`** (skill, by name)'
        $hits = 0
        foreach ($raw in $exLines) {
            if ($raw.TrimEnd([char]13).StartsWith($pat, [StringComparison]::Ordinal)) { $hits++ }
        }
        if ($hits -ne 1) { $missingByName += " $skill" }
    }
    if ($missingByName -eq '') {
        Pass 'explorer skill references name each skill for Copilot to load by name'
    }
    else {
        Fail 'explorer skill reference not in by-name form' "for:$missingByName"
    }
}
else {
    Fail 'explorer card checks need agents/explorer.agent.md and skills/bug-advocacy/SKILL.md'
}

# --- summary ----------------------------------------------------------------

Write-Host ''
Write-Host ("{0} passed, {1} failed" -f $script:PASS, $script:FAIL)
if ($script:FAIL -gt 0) { exit 1 } else { exit 0 }
