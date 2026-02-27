#!/usr/bin/env python3
"""
generate-tasks.py — Convert tasks JSON to importable CSV format.

Usage:
  python generate-tasks.py tasks.json [--format jira|azdo|linear|csv] [--output tasks.csv]

Formats:
  csv    — Generic CSV (default)
  jira   — Jira-compatible CSV import
  azdo   — Azure DevOps compatible CSV
  linear — Linear.app compatible CSV
"""

import json
import csv
import sys
import argparse
from pathlib import Path


def load_tasks(path: str) -> dict:
    with open(path, 'r') as f:
        return json.load(f)


def format_generic_csv(tasks: list, output: str):
    """Generic CSV format."""
    fieldnames = [
        'ID', 'Title', 'Phase', 'Phase Name', 'Workstream', 'Effort',
        'Effort Hours (Min)', 'Effort Hours (Max)', 'Risk', 'Dependencies',
        'Source Findings', 'Context', 'Instructions', 'Files Affected',
        'Acceptance Criteria', 'Labels'
    ]
    
    with open(output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for task in tasks:
            writer.writerow({
                'ID': task['id'],
                'Title': task['title'],
                'Phase': task.get('phase', ''),
                'Phase Name': task.get('phase_name', ''),
                'Workstream': task.get('workstream', ''),
                'Effort': task.get('effort', ''),
                'Effort Hours (Min)': task.get('effort_hours', {}).get('min', ''),
                'Effort Hours (Max)': task.get('effort_hours', {}).get('max', ''),
                'Risk': task.get('risk', ''),
                'Dependencies': ', '.join(task.get('depends_on', [])),
                'Source Findings': ', '.join(task.get('source_findings', [])),
                'Context': task.get('context', ''),
                'Instructions': task.get('instructions', ''),
                'Files Affected': ', '.join(task.get('files_affected', [])),
                'Acceptance Criteria': ' | '.join(task.get('acceptance_criteria', [])),
                'Labels': ', '.join(task.get('labels', []))
            })


def format_jira_csv(tasks: list, output: str):
    """Jira-compatible CSV import format."""
    fieldnames = [
        'Summary', 'Issue Type', 'Priority', 'Description', 'Labels',
        'Story Points', 'Component', 'Epic Link'
    ]
    
    priority_map = {
        'CRITICAL': 'Highest',
        'HIGH': 'High',
        'MEDIUM': 'Medium',
        'LOW': 'Low'
    }
    
    effort_points = {
        'XS': 1, 'S': 2, 'M': 5, 'L': 8, 'XL': 13
    }
    
    with open(output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for task in tasks:
            desc_parts = []
            if task.get('context'):
                desc_parts.append(f"h3. Context\n{task['context']}")
            if task.get('instructions'):
                desc_parts.append(f"h3. What to Do\n{task['instructions']}")
            if task.get('files_affected'):
                desc_parts.append(f"h3. Files Affected\n" + '\n'.join(f"* {f}" for f in task['files_affected']))
            if task.get('acceptance_criteria'):
                desc_parts.append(f"h3. Acceptance Criteria\n" + '\n'.join(f"* {ac}" for ac in task['acceptance_criteria']))
            if task.get('depends_on'):
                desc_parts.append(f"h3. Dependencies\n" + ', '.join(task['depends_on']))
            
            writer.writerow({
                'Summary': f"[{task['id']}] {task['title']}",
                'Issue Type': 'Task',
                'Priority': priority_map.get(task.get('risk', 'MEDIUM'), 'Medium'),
                'Description': '\n\n'.join(desc_parts),
                'Labels': ' '.join(task.get('labels', ['umbraco-upgrade'])),
                'Story Points': effort_points.get(task.get('effort', 'M'), 5),
                'Component': task.get('workstream', ''),
                'Epic Link': f"Phase {task.get('phase', '?')} — {task.get('phase_name', 'Umbraco Upgrade')}"
            })


def format_azdo_csv(tasks: list, output: str):
    """Azure DevOps compatible CSV import format."""
    fieldnames = [
        'Work Item Type', 'Title', 'Description', 'Priority', 'Effort',
        'Area Path', 'Tags', 'Acceptance Criteria'
    ]
    
    priority_map = {
        'CRITICAL': 1,
        'HIGH': 2,
        'MEDIUM': 3,
        'LOW': 4
    }
    
    effort_hours = {
        'XS': 0.5, 'S': 2, 'M': 8, 'L': 24, 'XL': 60
    }
    
    with open(output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for task in tasks:
            desc = f"<h3>Context</h3><p>{task.get('context', '')}</p>"
            desc += f"<h3>What to Do</h3><p>{task.get('instructions', '')}</p>"
            if task.get('files_affected'):
                desc += "<h3>Files Affected</h3><ul>" + ''.join(f"<li>{f}</li>" for f in task['files_affected']) + "</ul>"
            if task.get('depends_on'):
                desc += f"<h3>Dependencies</h3><p>{', '.join(task['depends_on'])}</p>"
            
            ac = '<br>'.join(f"☐ {ac}" for ac in task.get('acceptance_criteria', []))
            
            writer.writerow({
                'Work Item Type': 'Task',
                'Title': f"[{task['id']}] {task['title']}",
                'Description': desc,
                'Priority': priority_map.get(task.get('risk', 'MEDIUM'), 3),
                'Effort': effort_hours.get(task.get('effort', 'M'), 8),
                'Area Path': task.get('workstream', 'backend'),
                'Tags': '; '.join(task.get('labels', ['umbraco-upgrade'])),
                'Acceptance Criteria': ac
            })


def format_linear_csv(tasks: list, output: str):
    """Linear.app compatible CSV import format."""
    fieldnames = [
        'Title', 'Description', 'Priority', 'Estimate', 'Labels', 'Status'
    ]
    
    priority_map = {
        'CRITICAL': 'Urgent',
        'HIGH': 'High',
        'MEDIUM': 'Medium',
        'LOW': 'Low'
    }
    
    effort_points = {
        'XS': 1, 'S': 2, 'M': 5, 'L': 8, 'XL': 13
    }
    
    with open(output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for task in tasks:
            desc_parts = [task.get('context', '')]
            if task.get('instructions'):
                desc_parts.append(f"\n## What to Do\n{task['instructions']}")
            if task.get('acceptance_criteria'):
                desc_parts.append("\n## Acceptance Criteria\n" + '\n'.join(f"- [ ] {ac}" for ac in task['acceptance_criteria']))
            
            writer.writerow({
                'Title': f"[{task['id']}] {task['title']}",
                'Description': '\n'.join(desc_parts),
                'Priority': priority_map.get(task.get('risk', 'MEDIUM'), 'Medium'),
                'Estimate': effort_points.get(task.get('effort', 'M'), 5),
                'Labels': ', '.join(task.get('labels', ['umbraco-upgrade'])),
                'Status': 'Backlog'
            })


def main():
    parser = argparse.ArgumentParser(description='Convert tasks JSON to importable CSV')
    parser.add_argument('input', help='Path to tasks.json')
    parser.add_argument('--format', choices=['csv', 'jira', 'azdo', 'linear'], default='csv',
                        help='Output format (default: csv)')
    parser.add_argument('--output', '-o', help='Output file path (default: tasks-{format}.csv)')
    
    args = parser.parse_args()
    
    if not args.output:
        args.output = f"tasks-{args.format}.csv"
    
    data = load_tasks(args.input)
    tasks = data.get('tasks', [])
    
    formatters = {
        'csv': format_generic_csv,
        'jira': format_jira_csv,
        'azdo': format_azdo_csv,
        'linear': format_linear_csv
    }
    
    formatters[args.format](tasks, args.output)
    
    print(f"Generated {len(tasks)} tasks → {args.output} ({args.format} format)", file=sys.stderr)


if __name__ == '__main__':
    main()
