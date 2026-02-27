#!/usr/bin/env bash
# scan-project.sh — Scan an Umbraco 15 project for U17 upgrade findings
# Usage: ./scan-project.sh <solution-root> [scope]
# Scope: all | backend | backoffice | packages | devops (default: all)
#
# Outputs JSON findings to stdout. Pipe to file or consume from coordinator.

set -euo pipefail

SOLUTION_ROOT="${1:-.}"
SCOPE="${2:-all}"
FINDINGS_FILE=$(mktemp)

echo "[]" > "$FINDINGS_FILE"

add_finding() {
  local pattern_id="$1" severity="$2" category="$3" file="$4" line="$5" match="$6" description="$7" migration_action="$8" effort="$9"
  local relative_file="${file#$SOLUTION_ROOT/}"
  
  jq --arg pid "$pattern_id" --arg sev "$severity" --arg cat "$category" \
     --arg f "$relative_file" --argjson l "$line" --arg m "$match" \
     --arg d "$description" --arg ma "$migration_action" --arg e "$effort" \
     '. += [{"pattern_id":$pid,"severity":$sev,"category":$cat,"file":$f,"line":$l,"match":$m,"description":$d,"migration_action":$ma,"effort":$e}]' \
     "$FINDINGS_FILE" > "${FINDINGS_FILE}.tmp" && mv "${FINDINGS_FILE}.tmp" "$FINDINGS_FILE"
}

scan_grep() {
  local pattern_id="$1" severity="$2" category="$3" glob="$4" regex="$5" description="$6" migration_action="$7" effort="$8"
  
  while IFS=: read -r file line match; do
    [ -n "$file" ] && add_finding "$pattern_id" "$severity" "$category" "$file" "$line" "$match" "$description" "$migration_action" "$effort"
  done < <(grep -rn --include="$glob" -E "$regex" "$SOLUTION_ROOT" 2>/dev/null || true)
}

# ============================================================
# PROJ — Project Configuration
# ============================================================
scan_proj() {
  echo "Scanning: Project Configuration..." >&2
  
  scan_grep "PROJ-001" "CRITICAL" "proj" "*.csproj" '<TargetFramework>net9\.0</TargetFramework>' \
    "Target framework needs update to .NET 10" "Update to net10.0" "S"
  
  scan_grep "PROJ-002" "HIGH" "proj" "*.csproj" '<RazorCompileOn(Build|Publish)>' \
    "Obsolete Razor compile flags — remove for U17" "Remove these MSBuild properties" "XS"
  
  scan_grep "PROJ-003" "HIGH" "proj" "appsettings*.json" '"InMemoryAuto"' \
    "InMemoryAuto models mode requires new package in U17" "Add Umbraco.Cms.DevelopmentMode.Backoffice package" "S"
  
  scan_grep "PROJ-004" "HIGH" "proj" "appsettings*.json" 'TinyMCE|Umbraco\.TinyMCE' \
    "TinyMCE configuration found — removed in U16" "Remove config or install third-party TinyMCE package" "M"
  
  # Forms .lic files
  while IFS= read -r file; do
    [ -n "$file" ] && add_finding "PROJ-005" "HIGH" "proj" "$file" 0 "Forms .lic file" \
      "Old Forms license file — U17 requires subscription key" "Migrate license to subscription model" "S"
  done < <(find "$SOLUTION_ROOT" -name "*.lic" 2>/dev/null || true)
  
  scan_grep "PROJ-007" "HIGH" "proj" "*.csproj" 'NPoco' \
    "Direct NPoco package reference — major version update in U17" "Review NPoco 6.x breaking changes" "M"
  
  scan_grep "PROJ-008" "MEDIUM" "proj" "*.csproj" 'Swashbuckle' \
    "Swashbuckle reference — major version update in U17" "Update for Swashbuckle 10.x changes" "M"
}

# ============================================================
# CS — C# Server-Side Code
# ============================================================
scan_backend() {
  echo "Scanning: C# Backend Code..." >&2
  
  scan_grep "CS-001" "HIGH" "cs" "*.cs" \
    'GetAssemblyFile|ToSingleItemCollection|GenerateDataTable|CreateTableData|AddRowData|ChildrenAsTable|RetryUntilSuccessOrTimeout|RetryUntilSuccessOrMaxAttempts|HasFlagAny|DisposeIfDisposable|SafeCast|SanitizeThreadCulture' \
    "Usage of removed extension method" "Replace with .NET standard equivalent" "S"
  
  scan_grep "CS-003" "HIGH" "cs" "*.cs" ':\s*(MigrationBase|PackageMigrationBase)' \
    "Migration base class — binary-incompatible in U16+" "Recompile against U17 packages" "S"
  
  scan_grep "CS-004" "HIGH" "cs" "*.cs" 'IUrlProvider' \
    "Custom IUrlProvider — interface changed in U17" "Add Alias property and GetPreviewUrlAsync method" "M"
  
  scan_grep "CS-005" "HIGH" "cs" "*.cs" \
    'using NPoco|IUmbracoDatabase|Database\.Fetch|Database\.Query|Database\.Execute|Database\.Insert|Database\.Update|Database\.Delete' \
    "Direct NPoco/database usage — NPoco 6.x breaking changes" "Review and update for NPoco 6.x API changes" "M"
  
  scan_grep "CS-007" "MEDIUM" "cs" "*.cs" \
    'IExamineManager|ExamineIndex|ConfigureNamedOptions<LuceneDirectoryIndexOptions>|IndexingItemEventArgs' \
    "Examine customization — composer ordering changed in U16" "Add ComposeAfter attribute" "S"
  
  scan_grep "CS-012" "MEDIUM" "cs" "*.cs" 'DateTime\.Now' \
    "Potential server-time assumption — U17 uses UTC" "Review: replace with DateTime.UtcNow if DB-related" "S"
  
  scan_grep "CS-009" "LOW" "cs" "*.cs" 'ModelsMode\.' \
    "ModelsMode enum usage — use string constants in U17" "Replace with Constants.ModelsBuilder.ModelsModes" "XS"
  
  scan_grep "CS-011" "MEDIUM" "cs" "*.cs" 'IWebhookService|WebhookEvent' \
    "Custom webhook implementation — interface changes" "Review against U17 webhook API" "M"
}

# ============================================================
# BO — Backoffice / Client-Side Code
# ============================================================
scan_backoffice() {
  echo "Scanning: Backoffice Extensions..." >&2
  
  scan_grep "BO-001" "HIGH" "bo" "*.ts" '@umbraco-cms/backoffice/external/tiptap' \
    "Old TipTap import path — changed in U17" "Update to @umbraco-cms/backoffice/tiptap" "XS"
  
  scan_grep "BO-001" "HIGH" "bo" "*.js" '@umbraco-cms/backoffice/external/tiptap' \
    "Old TipTap import path — changed in U17" "Update to @umbraco-cms/backoffice/tiptap" "XS"
  
  scan_grep "BO-003" "MEDIUM" "bo" "*.ts" 'setManifest\(' \
    "setManifest() removed in U17 sections" "Replace with manifest property assignment" "S"
  
  scan_grep "BO-005" "HIGH" "bo" "*.ts" "fetch\(.*api" \
    "Fetch call may need credentials: include for U17 auth" "Add credentials: include to Management API calls" "S"
  
  scan_grep "BO-006" "CRITICAL" "bo" "*.js" 'angular\.module|ng-controller|ng-repeat|\$scope|\$http' \
    "AngularJS code found — must be completely rebuilt" "Rewrite using Lit web components" "XL"
  
  scan_grep "BO-006" "CRITICAL" "bo" "*.html" 'ng-controller|ng-repeat|ng-model|ng-click' \
    "AngularJS template found — must be completely rebuilt" "Rewrite using Lit web components" "XL"
  
  scan_grep "BO-007" "HIGH" "bo" "*.ts" 'tinymce|TinyMCE|tinyMCE' \
    "TinyMCE reference in client code — removed in U16" "Remove or rebuild as TipTap extension" "L"
  
  scan_grep "BO-007" "HIGH" "bo" "*.js" 'tinymce|TinyMCE|tinyMCE' \
    "TinyMCE reference in client code — removed in U16" "Remove or rebuild as TipTap extension" "L"
  
  # Manifest file inventory
  while IFS= read -r file; do
    [ -n "$file" ] && add_finding "BO-008" "MEDIUM" "bo" "$file" 0 "umbraco-package.json" \
      "Custom manifest file — review for U17 extension API changes" "Audit manifest against U17 extension docs" "M"
  done < <(find "$SOLUTION_ROOT" -name "umbraco-package.json" 2>/dev/null || true)
}

# ============================================================
# PKG — Package Audit
# ============================================================
scan_packages() {
  echo "Scanning: Packages..." >&2
  
  # Extract all NuGet PackageReferences
  while IFS= read -r line; do
    local pkg=$(echo "$line" | grep -oP 'Include="\K[^"]+')
    local ver=$(echo "$line" | grep -oP 'Version="\K[^"]+')
    local file=$(echo "$line" | cut -d: -f1)
    [ -n "$pkg" ] && add_finding "PKG-004" "MEDIUM" "pkg" "$file" 0 \
      "$pkg@$ver" "Package needs U17 compatibility check" "Check NuGet for U17-compatible version" "S"
  done < <(grep -rn --include="*.csproj" 'PackageReference' "$SOLUTION_ROOT" 2>/dev/null || true)
  
  # Specific Umbraco packages
  scan_grep "PKG-001" "CRITICAL" "pkg" "*.csproj" 'Umbraco\.Cms\.' \
    "Umbraco core package — must update to 17.x" "Update to Umbraco 17 packages" "S"
  
  scan_grep "PKG-002" "HIGH" "pkg" "*.csproj" 'Umbraco\.Forms' \
    "Umbraco Forms — version update + license migration required" "Update to Forms 17 + migrate license" "M"
  
  scan_grep "PKG-003" "MEDIUM" "pkg" "*.csproj" 'Umbraco\.Deploy' \
    "Umbraco Deploy — version update required" "Update to Deploy 17" "S"
}

# ============================================================
# DEVOPS — CI/CD and Deployment
# ============================================================
scan_devops() {
  echo "Scanning: DevOps Configuration..." >&2
  
  scan_grep "DEVOPS-001" "CRITICAL" "devops" "global.json" '"version":\s*"9\.' \
    ".NET SDK version needs update to 10.x" "Update global.json SDK version" "XS"
  
  scan_grep "DEVOPS-002" "HIGH" "devops" "Dockerfile*" 'mcr\.microsoft\.com/dotnet.*:9' \
    "Docker base image references .NET 9" "Update to .NET 10 base images" "S"
  
  # CI pipeline files
  for pattern in ".github/workflows/*.yml" "azure-pipelines.yml" ".gitlab-ci.yml"; do
    scan_grep "DEVOPS-003" "HIGH" "devops" "$pattern" 'net9\.0|dotnet-version.*9' \
      "CI pipeline references .NET 9" "Update to .NET 10" "S"
  done
  
  scan_grep "DEVOPS-004" "MEDIUM" "devops" "*.ps1" 'net9\.0' \
    "Deployment script references .NET 9" "Update framework reference" "XS"
  
  scan_grep "DEVOPS-004" "MEDIUM" "devops" "*.sh" 'net9\.0' \
    "Deployment script references .NET 9" "Update framework reference" "XS"
}

# ============================================================
# Main
# ============================================================
case "$SCOPE" in
  all)
    scan_proj
    scan_backend
    scan_backoffice
    scan_packages
    scan_devops
    ;;
  backend)  scan_proj; scan_backend ;;
  backoffice) scan_backoffice ;;
  packages) scan_packages ;;
  devops) scan_devops ;;
  *)
    echo "Unknown scope: $SCOPE" >&2
    echo "Usage: $0 <solution-root> [all|backend|backoffice|packages|devops]" >&2
    exit 1
    ;;
esac

# Output final findings
TOTAL=$(jq length "$FINDINGS_FILE")
CRITICAL=$(jq '[.[] | select(.severity=="CRITICAL")] | length' "$FINDINGS_FILE")
HIGH=$(jq '[.[] | select(.severity=="HIGH")] | length' "$FINDINGS_FILE")
MEDIUM=$(jq '[.[] | select(.severity=="MEDIUM")] | length' "$FINDINGS_FILE")
LOW=$(jq '[.[] | select(.severity=="LOW")] | length' "$FINDINGS_FILE")

jq -n \
  --arg scope "$SCOPE" \
  --arg root "$SOLUTION_ROOT" \
  --argjson total "$TOTAL" \
  --argjson critical "$CRITICAL" \
  --argjson high "$HIGH" \
  --argjson medium "$MEDIUM" \
  --argjson low "$LOW" \
  --slurpfile findings "$FINDINGS_FILE" \
  '{
    agent_scope: $scope,
    solution_root: $root,
    summary: { total: $total, critical: $critical, high: $high, medium: $medium, low: $low },
    findings: $findings[0]
  }'

rm -f "$FINDINGS_FILE"
