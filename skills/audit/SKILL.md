---
name: umbraco-upgrade-audit
description: >
  Scan and audit an Umbraco 15 project to identify all breaking changes, compatibility issues,
  and migration requirements for upgrading to Umbraco 17 (LTS). Use this skill whenever someone
  asks to audit, assess, analyze, or scan an Umbraco project for upgrade readiness. Also trigger
  when someone mentions "Umbraco upgrade", "Umbraco 17 migration", "breaking changes audit",
  "upgrade assessment", "upgrade readiness", or asks what needs to change to move from U15/U16 to U17.
  This skill produces a structured audit report that feeds into the umbraco-upgrade-architect skill.
---

# Umbraco Upgrade Audit (15 → 17)

Scan an Umbraco 15 codebase and produce a comprehensive inventory of everything affected by the upgrade to Umbraco 17.

## When to Use
- Assessing an Umbraco 15 (or 16) project for upgrade to 17
- Generating a pre-upgrade impact report
- Feeding findings into the architect skill for migration planning
- As the first step in the agent orchestration pipeline

## Prerequisites
- Access to the Umbraco project source code (solution root)
- Ability to run bash commands (grep, find, etc.)

## Workflow

### Step 1: Discover the Project Structure

Map the solution before scanning. Find:
- Solution file (.sln) location
- All .csproj files and their target frameworks
- appsettings*.json files
- Client-side code directories (App_Plugins, backoffice extensions)
- Docker and CI/CD configuration files
- global.json if present

```bash
# Example discovery commands
find . -name "*.sln" -o -name "*.csproj" -o -name "global.json" -o -name "appsettings*.json" | head -50
find . -name "umbraco-package.json" -o -name "package.json" | head -20
find . -path "*/App_Plugins/*" -name "*.ts" -o -path "*/App_Plugins/*" -name "*.js" | head -30
```

### Step 2: Load the Scan Patterns

Read the patterns reference file at the plugin's `references/patterns.md` (two directories up from this skill: `../../references/patterns.md`). This contains every pattern ID, regex, file glob, and severity. Use these patterns to drive systematic scanning.

### Step 3: Execute the Scan

Run the scan script at `scripts/scan-project.sh` (local to this skill directory) OR execute patterns manually. For each pattern category:

**PROJ — Project Configuration**
Scan .csproj files, appsettings, and global.json for framework versions, package references, and configuration flags.

**CS — C# Server-Side Code**
Scan all .cs files for removed extension methods, deprecated APIs, migration base classes, NPoco usage, Examine customizations, and date handling patterns.

**BO — Backoffice / Client-Side Code**
Scan .ts/.js files in App_Plugins and backoffice extension directories for old imports, AngularJS code, TinyMCE references, and manifest changes.

**PKG — Package & Dependency Audit**
Extract all NuGet PackageReferences and npm dependencies. Cross-reference against the package compatibility matrix in the plugin's `references/package-compatibility.md` (two directories up: `../../references/package-compatibility.md`).

**DEVOPS — CI/CD and Deployment**
Scan Dockerfiles, CI pipeline configs, and deployment scripts for .NET version references.

### Step 4: Compile the Audit Report

Produce a structured report with two outputs:

#### 4a. Machine-Readable (JSON)
```json
{
  "audit_metadata": {
    "project_name": "string",
    "current_version": "15.x.x",
    "target_version": "17.x.x",
    "scan_date": "ISO-8601",
    "solution_path": "string",
    "project_count": 0,
    "total_findings": 0
  },
  "summary": {
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0,
    "estimated_total_effort": "string"
  },
  "findings": [
    {
      "pattern_id": "CS-001",
      "severity": "HIGH",
      "category": "cs",
      "file": "relative/path/to/file.cs",
      "line": 42,
      "match": "content.ChildrenAsTable()",
      "description": "Usage of removed extension method",
      "migration_action": "Replace with IContentService query",
      "effort": "S",
      "breaking_change_ref": "breaking-changes-16-to-17.md#8"
    }
  ],
  "packages": {
    "nuget": [
      {
        "name": "string",
        "current_version": "string",
        "u17_compatible_version": "string|null",
        "status": "compatible|needs-update|incompatible|unknown",
        "notes": "string"
      }
    ],
    "npm": []
  },
  "risk_areas": [
    {
      "area": "Custom Data Access",
      "risk": "HIGH",
      "finding_count": 5,
      "description": "Multiple NPoco direct usages need updating for NPoco 6.x"
    }
  ]
}
```

#### 4b. Human-Readable (Markdown)
Generate a markdown report with:
- Executive summary (how big is this upgrade?)
- Findings grouped by severity, then by category
- Package compatibility table
- Risk areas ranked by impact
- Recommended upgrade strategy (stepped vs. direct)
- Next step: feed into umbraco-upgrade-architect

### Step 5: Save Outputs

Save both the JSON and markdown reports to the project workspace:
- `upgrade-audit/audit-report.json`
- `upgrade-audit/audit-report.md`

## Agent Mode Instructions

When running as part of an agent team:

- Accept a `scan_scope` parameter: `backend`, `backoffice`, `packages`, `devops`, or `all`
- Only scan the patterns relevant to your assigned scope
- Output findings as JSON to stdout (the coordinator will merge)
- Include your agent scope in the output metadata
- Do NOT generate the markdown report (the coordinator handles synthesis)

### Agent Output Schema
```json
{
  "agent_scope": "backend",
  "findings": [...],
  "packages": {...}
}
```

## Tips
- Large solutions may have thousands of .cs files. Use `grep -rn` with file globs rather than reading every file
- For AngularJS detection (BO-006), check App_Plugins directories specifically — this is the most effort-intensive finding if present
- The `DateTime.Now` pattern (CS-012) will have false positives. Focus on instances near database operations
- Some patterns overlap across U16 and U17 changes. Flag the earliest version where the break occurs
