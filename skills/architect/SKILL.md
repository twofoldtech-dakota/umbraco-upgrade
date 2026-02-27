---
name: umbraco-upgrade-architect
description: >
  Generate a formal migration architecture plan for upgrading an Umbraco project from version 15 to 17.
  Takes audit findings (from umbraco-upgrade-audit) and produces a phased, risk-assessed migration plan
  with decision points and recommended strategies. Use this skill when someone needs an upgrade plan,
  migration architecture, migration strategy, upgrade roadmap, or when they have audit results and
  need to turn them into an actionable technical plan. Also trigger when someone asks "how should we
  approach this upgrade", "what's the migration strategy", or "plan the Umbraco 17 upgrade".
  This skill produces an architecture plan that feeds into the umbraco-upgrade-tasker skill.
---

# Umbraco Upgrade Architect (15 → 17)

Transform audit findings into a structured, phased migration architecture plan. The plan should give a technical lead or architect everything they need to understand scope, sequence, risk, and decisions.

## When to Use
- After running the audit skill and having findings available
- When a tech lead needs to plan the upgrade approach
- When stakeholders need effort estimates and risk assessment
- As the second step in the agent orchestration pipeline

## Inputs
- Audit report JSON from `umbraco-upgrade-audit` (preferred)
- OR: manual description of the project and known issues
- Project context: team size, timeline constraints, environment details

## Workflow

### Step 1: Load References

Read these reference files from the plugin's root `references/` directory (two directories up from this skill: `../../references/`):
- `../../references/breaking-changes-15-to-16.md` — what breaks at the U16 boundary
- `../../references/breaking-changes-16-to-17.md` — what breaks at the U17 boundary
- `../../references/package-compatibility.md` — version mapping and compatibility
- `../../references/migration-playbook.md` — specific migration recipes

Also read the plan template local to this skill:
- `references/plan-template.md` — architecture document template

### Step 2: Analyze Audit Findings

If an audit report JSON is available, analyze it to determine:

1. **Upgrade Strategy Decision**
   - If the project has minimal custom code and few findings → recommend direct 15→17
   - If the project has significant backoffice extensions, custom migrations, or complex Examine customizations → recommend stepped 15→16→17
   - If AngularJS backoffice code is found (BO-006) → this is a major effort; flag as potential blocker

2. **Effort Classification**
   Map each finding to one of:
   - **Recompile**: Code is source-compatible, just needs rebuild (e.g., async migrations)
   - **Find-and-Replace**: Mechanical changes (e.g., import paths, namespace updates)
   - **Refactor**: Logic changes needed (e.g., removed extension methods, NPoco updates)
   - **Rebuild**: Significant rewrite (e.g., AngularJS → Lit, TinyMCE plugins → TipTap)
   - **Configure**: Configuration-only changes (e.g., HTTPS, UTC, Forms license)
   - **Verify**: No code change but needs testing (e.g., content after TipTap migration)

3. **Risk Assessment**
   For each area, assess:
   - **Probability of issues**: How likely are problems?
   - **Impact of failure**: What breaks if this goes wrong?
   - **Reversibility**: Can we roll back if needed?
   - **Risk level**: LOW / MEDIUM / HIGH / CRITICAL

### Step 3: Generate the Architecture Plan

Produce a plan using the template in `references/plan-template.md` (local to this skill directory). The plan has these sections:

#### 3a. Executive Summary
- Current state (U15 version, .NET 9, key packages)
- Target state (U17 LTS, .NET 10, key package versions)
- Recommended strategy (stepped or direct)
- Estimated total effort (range)
- Key risks and decisions needed

#### 3b. Upgrade Strategy
Define which approach and why:

**Option A: Stepped Upgrade (15 → 16 → 17)**
```
Phase 1: U15 → U16
  - TinyMCE → TipTap migration
  - Async migration recompile
  - Examine composer ordering
  - Package updates to U16 versions
  - Full regression test

Phase 2: U16 → U17
  - .NET 9 → .NET 10
  - UTC date migration
  - Models builder package
  - NPoco 6.x updates
  - Removed extension methods
  - Client-side import updates
  - Forms license migration
  - Full regression test
```

**Option B: Direct Upgrade (15 → 17)**
```
Single Phase:
  - Update all NuGet to U17
  - .NET 9 → .NET 10
  - Address ALL breaking changes from both U16 and U17
  - Full regression test
```

#### 3c. Phased Plan

Regardless of strategy, break work into these phases:

**Phase 0: Preparation** (before touching code)
- Back up database and media
- Document current state
- Audit third-party package compatibility
- Set up staging environment
- Migrate Forms license (if applicable)
- Decisions: approve strategy, confirm package replacements

**Phase 1: Framework & Infrastructure**
- Update target framework to .NET 10
- Update global.json, Docker, CI/CD
- Update all Umbraco NuGet packages
- Fix compilation errors from framework change
- Verify the solution builds

**Phase 2: Server-Side Breaking Changes**
- Apply migration playbook recipes for each finding
- Removed extension methods → replacements
- NPoco 6.x API updates
- IUrlProvider interface changes
- Examine composer ordering
- UTC date handling in custom code
- Models builder mode changes

**Phase 3: Client-Side / Backoffice Changes**
- TipTap import path updates
- Current-user import updates
- Section context changes
- Management API credentials
- Rebuild AngularJS extensions (if any — this may be its own project)

**Phase 4: Configuration & Licensing**
- HTTPS default handling
- UTC migration configuration
- Forms license key in appsettings
- Unattended upgrade configuration
- Review all appsettings changes

**Phase 5: Testing & Validation**
- Run application in maintenance mode
- Verify automatic database migrations complete
- Content spot-check (especially RTE content)
- Test all custom backoffice extensions
- Test custom search/indexing
- Test forms and workflows
- Test deployment pipeline end-to-end
- Performance validation
- Cross-browser testing of backoffice

**Phase 6: Deployment**
- Deploy to staging, full regression
- Deploy to production with rollback plan
- Monitor logs for migration issues
- Validate UTC date migration results

#### 3d. Decision Register

Identify all decisions that need human input before proceeding:

| ID | Decision | Options | Recommendation | Impact | Needed By |
|----|----------|---------|----------------|--------|-----------|
| D-001 | Upgrade strategy | Stepped vs Direct | Based on findings | HIGH | Phase 0 |
| D-002 | TinyMCE handling | Auto-migrate vs 3rd party package | Auto-migrate | MEDIUM | Phase 0 |
| D-003 | Models builder mode | Keep InMemoryAuto vs switch to SourceCodeAuto | Switch | LOW | Phase 2 |
| ... | ... | ... | ... | ... | ... |

#### 3e. Risk Register

| ID | Risk | Probability | Impact | Mitigation | Owner |
|----|------|-------------|--------|------------|-------|
| R-001 | Third-party package incompatible | MEDIUM | HIGH | Identify alternatives early | Tech Lead |
| R-002 | UTC migration corrupts dates | LOW | HIGH | Test on DB backup first | DBA |
| R-003 | TipTap content rendering differs | MEDIUM | MEDIUM | Spot-check 50 content pages | QA |
| ... | ... | ... | ... | ... | ... |

### Step 4: Save the Plan

Save the architecture plan as:
- `upgrade-plan/architecture-plan.md` — the full document
- `upgrade-plan/architecture-plan.json` — structured data for the tasker skill

## Agent Mode Instructions

When running as the coordinator/architect agent:

- Accept merged findings from scanner agents
- Deduplicate findings across agent outputs
- Generate the plan using the full template
- Output both markdown and JSON formats
- Pass the JSON plan to the tasker agent

## Output Schema (JSON)

```json
{
  "plan_metadata": {
    "project_name": "string",
    "current_version": "15.x.x",
    "target_version": "17.x.x",
    "strategy": "stepped|direct",
    "estimated_effort_days": { "min": 0, "max": 0 },
    "team_size": 0,
    "plan_date": "ISO-8601"
  },
  "phases": [
    {
      "phase_number": 0,
      "name": "Preparation",
      "description": "string",
      "estimated_days": { "min": 0, "max": 0 },
      "dependencies": [],
      "work_items": [
        {
          "id": "WI-001",
          "title": "string",
          "description": "string",
          "category": "recompile|find-replace|refactor|rebuild|configure|verify",
          "effort": "XS|S|M|L|XL",
          "risk": "LOW|MEDIUM|HIGH|CRITICAL",
          "workstream": "backend|backoffice|devops|qa|all",
          "source_findings": ["CS-001", "CS-005"],
          "playbook_ref": "migration-playbook.md#7"
        }
      ]
    }
  ],
  "decisions": [...],
  "risks": [...]
}
```

## Tips
- Be conservative with effort estimates — enterprise projects always have surprises
- If AngularJS backoffice code is found, the upgrade may need to be treated as a partial rebuild with its own project timeline
- The UTC date migration can be slow on large databases — flag this for DBA attention
- Forms license migration is an administrative task, not a code task — it needs to happen early
- Always recommend a staging environment test before production deployment
