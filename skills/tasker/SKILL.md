---
name: umbraco-upgrade-tasker
description: >
  Decompose an Umbraco upgrade architecture plan into developer-ready tasks with acceptance criteria,
  effort estimates, dependencies, and workstream assignments. Use this skill when someone needs to
  break down an upgrade plan into tickets, work items, or tasks for a dev team. Also trigger when
  someone asks to "create tickets", "break this into tasks", "generate work items", "make this
  actionable for the team", or "create a task board" from an Umbraco upgrade plan. Outputs in
  multiple formats: markdown, CSV (for Jira/Azure DevOps import), and structured JSON.
---

# Umbraco Upgrade Tasker (15 → 17)

Convert an architecture plan into discrete, assignable, dev-ready tasks that a team can pick up and execute without needing to understand the full upgrade context.

## When to Use
- After the architect skill has produced a migration plan
- When a tech lead needs to populate a project board
- When work needs to be distributed across a team
- As the final step in the agent orchestration pipeline

## Inputs
- Architecture plan JSON from `umbraco-upgrade-architect` (preferred)
- OR: architecture plan markdown
- OR: audit findings + manual plan description
- Team context: size, roles, sprint length (optional, for sprint planning)

## Core Principles

Each task must be **independently understandable** by a developer who hasn't read the full plan. This means:

1. **Self-contained context**: The task description explains WHY this change is needed, not just WHAT to do
2. **Specific file references**: Where possible, list the exact files that need to change
3. **Acceptance criteria**: Clear, testable conditions for "done"
4. **Migration recipe reference**: Link to the specific playbook recipe so the dev has step-by-step guidance
5. **Dependencies are explicit**: If task B requires task A, say so clearly

## Workflow

### Step 1: Load the Plan

Read the architecture plan (JSON or markdown). Extract:
- All work items from each phase
- The dependency chain between phases
- Risk levels and effort estimates
- Workstream assignments

### Step 2: Decompose Work Items into Tasks

Each work item from the plan may become one or more tasks. The decomposition rules:

**1:1 mapping** (work item = task) when:
- The work is small (XS or S effort)
- It touches a single area
- One developer can complete it independently

**1:N decomposition** (work item → multiple tasks) when:
- The work item spans multiple files/projects
- It mixes code changes with configuration changes
- It has distinct "implement" and "verify" steps
- Different team members would work on different parts

### Task Decomposition Rules

For each finding category, use these decomposition patterns:

**Recompile tasks:**
- Single task: "Recompile [component] against U17 packages"
- Include: which projects, expected outcome, how to verify

**Find-and-Replace tasks:**
- Single task per pattern type (group similar changes)
- Include: regex pattern, file glob, before/after example
- AC: "grep returns zero results for old pattern"

**Refactor tasks:**
- One task per logical unit of change
- Include: specific recipe reference from migration playbook
- Include: relevant test coverage expectations
- AC: "code compiles + unit tests pass + manual verification of [specific behavior]"

**Rebuild tasks:**
- Break into: research/spike → implement → integrate → test
- Each sub-task is independently assignable
- Flag rebuild tasks with "LARGE — may need refinement" if > L effort

**Configure tasks:**
- One task per configuration area
- Include: exact JSON/XML to add/change
- AC: "application starts successfully with new configuration"

**Verify tasks:**
- Pair with related code/config tasks
- Include: specific test scenarios to run
- AC: detailed test script or checklist

### Step 3: Assign Workstreams

Every task gets a primary workstream:

| Workstream | Roles | Typical Tasks |
|-----------|-------|---------------|
| **backend** | .NET developers | C# changes, API updates, data access |
| **backoffice** | Frontend / Umbraco developers | Lit components, extension updates |
| **devops** | DevOps / infrastructure | CI/CD, Docker, deployment config |
| **qa** | QA / testers | Regression testing, content verification |
| **admin** | Tech lead / PM | License migration, decision-making |

### Step 4: Build Dependency Graph

Map task dependencies:
- Phase-level: Phase N tasks generally depend on Phase N-1
- Task-level: Some tasks within a phase have internal dependencies
- Parallel opportunities: Identify tasks that can run in parallel across workstreams

Express as:
```
TASK-001 → TASK-005 (TASK-005 requires TASK-001 complete)
TASK-002 ∥ TASK-003 (can run in parallel)
```

### Step 5: Generate Output

Produce tasks in three formats:

#### 5a. Markdown Task List

Use the task template at `assets/task-template.md` (local to this skill directory). For each task:
```markdown
### TASK-XXX: [Title]

**Phase:** [N] — [Phase Name]
**Workstream:** [backend | backoffice | devops | qa | admin]
**Effort:** [XS | S | M | L | XL]
**Risk:** [LOW | MEDIUM | HIGH]
**Depends On:** [TASK-YYY, TASK-ZZZ] or None
**Source Findings:** [CS-001, CS-005]
**Playbook Reference:** migration-playbook.md#[section]

#### Context
[WHY this change is needed — 2-3 sentences a dev can read to understand the purpose]

#### What to Do
[Specific instructions — files to change, patterns to search, code to update]

#### Files Affected
- `src/path/to/file.cs` (line ~42)
- `src/path/to/other-file.cs`

#### Acceptance Criteria
- [ ] [Specific, testable criterion]
- [ ] [Another criterion]
- [ ] Code compiles without errors
- [ ] Existing tests pass

#### PR Description Template
```
**What:** [One-line summary]
**Why:** [Breaking change reference]
**How:** [Approach taken]
**Testing:** [How this was verified]
**Related:** TASK-XXX
```
```

#### 5b. CSV for Project Management Import

Generate a CSV compatible with Jira/Azure DevOps/Linear import:

```csv
ID,Title,Description,Type,Priority,Effort,Workstream,Phase,Dependencies,Acceptance Criteria,Labels
TASK-001,"Update target framework to .NET 10","...","Task","Critical","S","devops","Phase 1","","Solution builds on .NET 10","umbraco-upgrade,framework"
```

Use `scripts/generate-tasks.py` (local to this skill directory) for CSV generation:
```bash
python3 scripts/generate-tasks.py tasks.json --format csv --output tasks.csv
python3 scripts/generate-tasks.py tasks.json --format azdo --output tasks-azdo.csv
python3 scripts/generate-tasks.py tasks.json --format jira --output tasks-jira.csv
```

#### 5c. JSON (Structured)

```json
{
  "task_metadata": {
    "project_name": "string",
    "total_tasks": 0,
    "total_effort_days": { "min": 0, "max": 0 },
    "generated_date": "ISO-8601"
  },
  "tasks": [
    {
      "id": "TASK-001",
      "title": "string",
      "phase": 1,
      "phase_name": "Framework & Infrastructure",
      "workstream": "devops",
      "effort": "S",
      "effort_hours": { "min": 1, "max": 4 },
      "risk": "LOW",
      "depends_on": [],
      "source_findings": ["PROJ-001"],
      "playbook_ref": "migration-playbook.md#1",
      "context": "string",
      "instructions": "string",
      "files_affected": ["src/MyProject/MyProject.csproj"],
      "acceptance_criteria": ["Solution builds targeting net10.0"],
      "labels": ["umbraco-upgrade", "framework"],
      "pr_template": "string"
    }
  ],
  "dependency_graph": {
    "TASK-001": { "depends_on": [], "blocks": ["TASK-005", "TASK-006"] },
    "TASK-005": { "depends_on": ["TASK-001"], "blocks": [] }
  },
  "workstream_summary": {
    "backend": { "task_count": 0, "total_effort_hours": { "min": 0, "max": 0 } },
    "backoffice": { "task_count": 0, "total_effort_hours": { "min": 0, "max": 0 } },
    "devops": { "task_count": 0, "total_effort_hours": { "min": 0, "max": 0 } },
    "qa": { "task_count": 0, "total_effort_hours": { "min": 0, "max": 0 } },
    "admin": { "task_count": 0, "total_effort_hours": { "min": 0, "max": 0 } }
  },
  "sprint_suggestions": [
    {
      "sprint": 1,
      "theme": "Foundation",
      "tasks": ["TASK-001", "TASK-002", "TASK-003"],
      "parallel_tracks": [
        { "workstream": "devops", "tasks": ["TASK-001"] },
        { "workstream": "admin", "tasks": ["TASK-002"] }
      ]
    }
  ]
}
```

### Step 6: Save Outputs

Save to:
- `upgrade-tasks/tasks.md` — full markdown task list
- `upgrade-tasks/tasks.csv` — importable CSV
- `upgrade-tasks/tasks.json` — structured JSON
- `upgrade-tasks/dependency-graph.md` — visual dependency map

## Agent Mode Instructions

When running as the tasker agent:
- Accept the architecture plan JSON from the architect agent
- Read the migration playbook at the plugin's `references/migration-playbook.md` (two directories up: `../../references/migration-playbook.md`) for migration recipes to reference in tasks
- Generate all three output formats
- Include sprint suggestions if team context is provided
- Output files to the workspace directory

## Effort → Hours Mapping

| Size | Hours (min) | Hours (max) | Typical Work |
|------|-------------|-------------|-------------|
| XS | 0.25 | 0.5 | Config change, single find-replace |
| S | 0.5 | 4 | Small refactor, single file update |
| M | 4 | 16 | Multi-file refactor, API migration |
| L | 16 | 40 | Component rebuild, complex migration |
| XL | 40 | 80+ | Full rewrite (e.g., AngularJS → Lit) |

## Tips
- Number tasks sequentially within phases: TASK-101, TASK-102 (Phase 1), TASK-201, TASK-202 (Phase 2), etc.
- Always include a "Verify [area]" task after code change tasks — testing is work too
- Group find-and-replace tasks together when the same developer would do them in one sitting
- For XL tasks (rebuilds), add a "Spike: Research approach for [component]" task first
- CSV format should match the team's actual PM tool — ask about custom fields if needed
- Sprint suggestions assume 2-week sprints unless told otherwise
