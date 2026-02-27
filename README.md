# Umbraco Upgrade Plugin (15 → 17)

A Claude Code plugin for planning and executing Umbraco 15 → 17 (LTS) upgrades. Works in two modes:

1. **Skills Mode** — Human-driven, sequential workflow in Claude Code
2. **Agent Mode** — Parallelized, autonomous pipeline using Claude Code agent teams

## Installation

### From Marketplace

#### Add the marketplace
```bash
/plugin marketplace add twofoldtech-dakota/umbraco-upgrade
```

#### Install the plugin
```bash
/plugin install umbraco-upgrade@twofoldtech-dakota-plugin-architect
```

### From GitHub (Direct)

```bash
/plugin install https://github.com/twofoldtech-dakota/umbraco-upgrade
```

### Local Development

```bash
# Clone the repo
git clone https://github.com/twofoldtech-dakota/umbraco-upgrade.git

# Load as a local plugin
claude --plugin-dir ./umbraco-upgrade
```

## Quick Start

### Skills Mode (Sequential, Human-Driven)

```
1. /umbraco-upgrade:audit    → "Scan my project at /path/to/solution"
2. /umbraco-upgrade:architect → "Generate a migration plan from the audit"
3. /umbraco-upgrade:tasker    → "Break the plan into dev tasks for Azure DevOps"
```

### Agent Mode (Automated Pipeline)

The coordinator agent handles the full pipeline:

```bash
claude -p "Using the upgrade-coordinator agent, run the full upgrade pipeline \
  for /path/to/solution. Output everything to ./upgrade-output/"
```

Or step-by-step with human review gates:

```bash
# Step 1: Audit
claude -p "Using /umbraco-upgrade:audit, scan the project at /path/to/solution"

# [Review audit report]

# Step 2: Architect
claude -p "Using /umbraco-upgrade:architect, generate a migration plan from upgrade-audit/audit-report.json"

# [Review plan, make decisions]

# Step 3: Tasker
claude -p "Using /umbraco-upgrade:tasker, generate tasks from upgrade-plan/architecture-plan.json. Export as Azure DevOps CSV."
```

## Directory Structure

```
umbraco-upgrade/
├── .claude-plugin/
│   ├── plugin.json                    ← Plugin manifest
│   └── marketplace.json               ← Marketplace registry
├── skills/                            ← Agent Skills (model-invoked)
│   ├── audit/
│   │   ├── SKILL.md                   ← Codebase auditing skill
│   │   └── scripts/
│   │       └── scan-project.sh        ← Automated scanner
│   ├── architect/
│   │   ├── SKILL.md                   ← Migration planning skill
│   │   └── references/
│   │       └── plan-template.md       ← Architecture document template
│   └── tasker/
│       ├── SKILL.md                   ← Task decomposition skill
│       ├── scripts/
│       │   └── generate-tasks.py      ← CSV export (Jira/AzDO/Linear)
│       └── assets/
│           └── task-template.md       ← Per-task markdown template
├── agents/                            ← Subagents (Claude can invoke)
│   ├── coordinator.md                 ← Orchestrates full pipeline
│   ├── scanner.md                     ← Scans specific codebase areas
│   ├── architect.md                   ← Generates migration plan
│   └── tasker.md                      ← Decomposes plan into tasks
├── references/                        ← Shared knowledge layer
│   ├── breaking-changes-15-to-16.md   ← U16 breaking changes
│   ├── breaking-changes-16-to-17.md   ← U17 breaking changes
│   ├── package-compatibility.md       ← Version matrix
│   ├── patterns.md                    ← Scan patterns (regex + severity)
│   └── migration-playbook.md          ← Step-by-step migration recipes
├── README.md                          ← You are here
└── LICENSE
```

## What Each Skill Does

| Skill | Input | Output | Effort |
|-------|-------|--------|--------|
| **audit** | Umbraco 15 source code | Findings report (JSON + MD) | 5-15 min |
| **architect** | Audit findings | Phased migration plan | 5-10 min |
| **tasker** | Architecture plan | Dev-ready tasks (MD + CSV + JSON) | 5-10 min |

## Agent Team Architecture

```
┌──────────────────────────────────────────────┐
│           upgrade-coordinator                │
│  Spawns scanners, merges findings,           │
│  runs architect + tasker pipeline            │
└──────────┬───────────────────────────────────┘
           │ spawns parallel agents
    ┌──────┼──────────┬───────────┐
    ▼      ▼          ▼           ▼
┌────────┐┌────────┐┌──────────┐┌─────────┐
│Backend ││Backoff ││Package   ││DevOps   │
│Scanner ││ice     ││Auditor   ││Scanner  │
│        ││Scanner ││          ││         │
└────┬───┘└────┬───┘└─────┬────┘└────┬────┘
     └─────────┴──────────┴──────────┘
                    │
              ┌─────▼──────┐
              │  Architect  │
              │  Agent      │
              └─────┬──────┘
                    │
              ┌─────▼──────┐
              │  Tasker     │
              │  Agent      │
              └────────────┘
```

## Key Breaking Changes Covered

### From Umbraco 16
- TinyMCE → TipTap migration
- Async package migrations (binary-incompatible)
- Examine composer ordering

### From Umbraco 17
- .NET 9 → .NET 10
- System dates → UTC
- InMemoryAuto → separate package
- NPoco 5.x → 6.x
- Swashbuckle → 10.x
- Removed extension methods
- TipTap import path changes
- IUrlProvider interface changes
- HTTPS enabled by default
- Backoffice auth tightened
- Forms license model change

## Output Directory Structure

After a full pipeline run:

```
output/
├── upgrade-audit/
│   ├── audit-report.json       # Machine-readable findings
│   ├── audit-report.md         # Human-readable report
│   └── scans/                  # Raw scan outputs (if parallel)
│       ├── backend.json
│       ├── backoffice.json
│       ├── packages.json
│       └── devops.json
├── upgrade-plan/
│   ├── architecture-plan.md    # Full architecture document
│   └── architecture-plan.json  # Structured plan data
└── upgrade-tasks/
    ├── tasks.md                # Markdown task list
    ├── tasks.json              # Structured task data
    ├── tasks-azdo.csv          # Azure DevOps import
    ├── tasks-jira.csv          # Jira import
    └── dependency-graph.md     # Visual dependency map
```

## Customization

### Adding New Patterns
Edit `references/patterns.md` to add scan patterns. Follow the existing format with pattern ID, severity, file glob, and regex.

### Adding Migration Recipes
Edit `references/migration-playbook.md` to add new recipes. Each recipe should have before/after code examples.

### Changing CSV Format
The `skills/tasker/scripts/generate-tasks.py` script supports Jira, Azure DevOps, Linear, and generic CSV. Add new formatters by adding a `format_*_csv` function.

## Requirements

- **Skills Mode**: Claude Code with file system access
- **Agent Mode**: Claude Code with subagent capability (`claude -p`)
- **Scripts**: bash, jq (for scan-project.sh), Python 3 (for generate-tasks.py)

## License

MIT
