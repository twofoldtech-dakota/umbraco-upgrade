# Scan Patterns Reference

Patterns to detect in an Umbraco 15 codebase when planning upgrade to 17. Each pattern includes what to search for, where to look, and the severity of the finding.

## Pattern Categories

### PROJ — Project Configuration
| ID | Pattern | File Glob | Regex/Search | Severity |
|----|---------|-----------|-------------|----------|
| PROJ-001 | Target framework | `*.csproj` | `<TargetFramework>net9\.0</TargetFramework>` | CRITICAL |
| PROJ-002 | Razor compile flags | `*.csproj` | `<RazorCompileOn(Build\|Publish)>` | HIGH |
| PROJ-003 | InMemoryAuto models mode | `appsettings*.json` | `"InMemoryAuto"` | HIGH |
| PROJ-004 | TinyMCE references | `appsettings*.json` | `TinyMCE\|Umbraco\.TinyMCE` | HIGH |
| PROJ-005 | Forms .lic files | `**/*.lic` | File existence check | HIGH |
| PROJ-006 | UseHttps not set | `appsettings*.json` | Absence of `"UseHttps"` (defaults change) | MEDIUM |
| PROJ-007 | NPoco direct reference | `*.csproj` | `NPoco` in PackageReference | HIGH |
| PROJ-008 | Swashbuckle reference | `*.csproj` | `Swashbuckle` in PackageReference | MEDIUM |

### CS — C# Server-Side Code
| ID | Pattern | File Glob | Regex/Search | Severity |
|----|---------|-----------|-------------|----------|
| CS-001 | Removed extension methods | `*.cs` | `GetAssemblyFile\|ToSingleItemCollection\|GenerateDataTable\|CreateTableData\|AddRowData\|ChildrenAsTable\|RetryUntilSuccessOrTimeout\|RetryUntilSuccessOrMaxAttempts\|HasFlagAny\|DisposeIfDisposable\|SafeCast\|SanitizeThreadCulture` | HIGH |
| CS-002 | NameValueCollection extensions | `*.cs` | `\.AsEnumerable\(\)\|\.ContainsKey\(\)\|\.GetValue\(` on NameValueCollection context | MEDIUM |
| CS-003 | Migration base classes | `*.cs` | `:\s*(MigrationBase\|PackageMigrationBase)` | HIGH |
| CS-004 | Custom IUrlProvider | `*.cs` | `IUrlProvider` | HIGH |
| CS-005 | NPoco direct usage | `*.cs` | `using NPoco\|IUmbracoDatabase\|Database\.Fetch\|Database\.Query\|Database\.Execute\|Database\.Insert\|Database\.Update\|Database\.Delete` | HIGH |
| CS-006 | DateTime.Kind checks | `*.cs` | `DateTimeKind\.Utc\|\.Kind\s*==` in property editor contexts | MEDIUM |
| CS-007 | Examine customizations | `*.cs` | `IExamineManager\|ExamineIndex\|ConfigureNamedOptions<LuceneDirectoryIndexOptions>\|IndexingItemEventArgs` | MEDIUM |
| CS-008 | Custom Examine composers | `*.cs` | `IComposer.*Examine\|ComposeAfter.*Examine\|ComposeBefore.*Examine` | MEDIUM |
| CS-009 | Custom ModelsMode enum usage | `*.cs` | `ModelsMode\.` | LOW |
| CS-010 | DataTable usage with Umbraco | `*.cs` | `DataTable.*Umbraco\|ChildrenAsTable\|CreateTableData` | MEDIUM |
| CS-011 | Custom webhook implementations | `*.cs` | `IWebhookService\|WebhookEvent` | MEDIUM |
| CS-012 | Server time assumptions | `*.cs` | `DateTime\.Now` in DB-related contexts (should be `DateTime.UtcNow`) | MEDIUM |
| CS-013 | Color picker string access | `*.cs, *.cshtml` | `\.Value<string>.*color\|GetPropertyValue<string>.*color` | LOW |

### BO — Backoffice / Client-Side Code
| ID | Pattern | File Glob | Regex/Search | Severity |
|----|---------|-----------|-------------|----------|
| BO-001 | Old TipTap import | `*.ts, *.js` | `@umbraco-cms/backoffice/external/tiptap` | HIGH |
| BO-002 | Old user imports | `*.ts, *.js` | `from\s+['"]@umbraco-cms/backoffice/user['"]` for moved components | MEDIUM |
| BO-003 | setManifest usage | `*.ts, *.js` | `setManifest\(` | MEDIUM |
| BO-004 | Section extending HTMLElement | `*.ts, *.js` | `extends\s+HTMLElement` in section context | MEDIUM |
| BO-005 | Missing credentials include | `*.ts, *.js` | `fetch\(.*api.*\)` without `credentials:\s*['"]include['"]` | HIGH |
| BO-006 | AngularJS backoffice code | `*.js, *.html` | `angular\.module\|ng-controller\|ng-repeat\|$scope\|$http` | CRITICAL |
| BO-007 | TinyMCE plugins | `*.ts, *.js` | `tinymce\|TinyMCE\|tinyMCE` | HIGH |
| BO-008 | Custom manifest files | `umbraco-package.json` | File existence + contents audit | MEDIUM |

### PKG — Package & Dependency Audit
| ID | Pattern | File Glob | Regex/Search | Severity |
|----|---------|-----------|-------------|----------|
| PKG-001 | Umbraco core packages | `*.csproj` | `Umbraco\.Cms\.\*` — check version compatibility | CRITICAL |
| PKG-002 | Umbraco Forms package | `*.csproj` | `Umbraco\.Forms` — version + license check | HIGH |
| PKG-003 | Umbraco Deploy package | `*.csproj` | `Umbraco\.Deploy` | MEDIUM |
| PKG-004 | Third-party packages | `*.csproj` | All non-Umbraco `PackageReference` — compatibility unknown | MEDIUM |
| PKG-005 | npm packages | `package.json` | `@umbraco-cms/*` packages — version compatibility | MEDIUM |

### DEVOPS — CI/CD and Deployment
| ID | Pattern | File Glob | Regex/Search | Severity |
|----|---------|-----------|-------------|----------|
| DEVOPS-001 | .NET SDK version | `global.json` | `"version": "9.` | CRITICAL |
| DEVOPS-002 | Docker base images | `Dockerfile*` | `mcr.microsoft.com/dotnet.*:9` | HIGH |
| DEVOPS-003 | CI pipeline SDK | `.github/workflows/*.yml, azure-pipelines.yml, .gitlab-ci.yml, *.teamcity*` | `.NET 9\|dotnet-version.*9\|net9.0` | HIGH |
| DEVOPS-004 | Deployment scripts | `*.ps1, *.sh` | `net9.0\|dotnet publish` framework references | MEDIUM |

## Output Schema

Each finding should be reported as:

```json
{
  "pattern_id": "CS-001",
  "severity": "HIGH",
  "file": "src/MyProject/Extensions/ContentExtensions.cs",
  "line": 42,
  "match": "content.ChildrenAsTable()",
  "description": "Usage of removed extension method 'ChildrenAsTable'",
  "migration_action": "Replace with custom implementation or IContentService query",
  "effort": "S"
}
```

Effort t-shirt sizes: XS (< 30 min), S (< 2 hrs), M (< 1 day), L (< 3 days), XL (> 3 days)
