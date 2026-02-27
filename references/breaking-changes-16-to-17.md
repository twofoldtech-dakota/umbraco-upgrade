# Breaking Changes: Umbraco 16 → 17

Umbraco 17 is the new Long-Term Support (LTS) release.

## Critical Changes

### 1. .NET 10 Target Framework
- **Impact**: HIGH
- **Area**: Project configuration, all compiled code, NuGet packages
- U17 requires .NET 10 (up from .NET 9)
- All `.csproj` files must update `<TargetFramework>` to `net10.0`
- All referenced class libraries must also target .NET 10
- **Scan for**: `<TargetFramework>net9.0</TargetFramework>` in all .csproj files, incompatible NuGet packages
- **Migration path**: Update target framework, verify all dependencies support .NET 10
- **Risk**: Third-party packages may not yet support .NET 10; rebuild all projects

### 2. System Dates Converted to UTC
- **Impact**: HIGH
- **Area**: Database, date handling, scheduling, content publishing dates
- All system dates now stored in UTC (previously server local time)
- Automatic migration runs on upgrade to convert existing dates
- Migration detects server time zone and converts accordingly
- **Scan for**: Custom code reading/writing dates directly from DB, custom SQL queries with date comparisons, scheduled publishing logic, date display code
- **Migration path**: Allow auto-migration; optionally configure time zone override or disable migration
- **Configuration**:
  ```json
  {
    "Umbraco": {
      "CMS": {
        "SystemDateMigration": {
          "Enabled": true,
          "LocalServerTimeZone": "Eastern Standard Time"
        }
      }
    }
  }
  ```
- **Risk**: Date display issues if custom code assumes server-local time; large databases may have slow migration

### 3. InMemoryAuto Models Builder → Separate Package
- **Impact**: HIGH for development workflow
- **Area**: Models builder, Razor runtime compilation, development mode
- `InMemoryAuto` models builder and Razor runtime compilation moved to `Umbraco.Cms.DevelopmentMode.Backoffice` package
- Razor runtime compilation is obsolete in .NET 10 and prevents Hot Reload
- **Scan for**: `ModelsMode` set to `InMemoryAuto` in appsettings, Razor runtime compilation usage, `RazorCompileOnBuild`/`RazorCompileOnPublish` in .csproj
- **Migration path**:
  - If using `InMemoryAuto`: Add `Umbraco.Cms.DevelopmentMode.Backoffice` package reference
  - If using `AppData`, `SourceCodeAuto`, `SourceCodeManual`: No action needed
  - Remove `<RazorCompileOnBuild>false</RazorCompileOnBuild>` and `<RazorCompileOnPublish>false</RazorCompileOnPublish>` from .csproj
- **Risk**: Build failures if package not added; Hot Reload disabled if package is added

### 4. NPoco Major Version Update (5.x → 6.x)
- **Impact**: HIGH for custom data access
- **Area**: Database access, repositories, custom queries
- NPoco updated from 5.7.1 to 6.1.0 (major version bump)
- API changes may affect custom code using NPoco directly
- **Scan for**: Direct `NPoco` usage, `IUmbracoDatabase` custom queries, `Database.Fetch<>`, `Database.Query<>`, custom repository patterns
- **Migration path**: Review NPoco 6.x changelog, update any breaking API calls
- **Risk**: Runtime exceptions in custom data access code

### 5. Swashbuckle Major Version Update (to 10.0.1)
- **Impact**: MEDIUM
- **Area**: API documentation, Swagger/OpenAPI
- Namespace changes, nullability changes, type changes
- **Scan for**: Custom Swagger configuration, `AddSwaggerGen`, custom `IOperationFilter`, `IDocumentFilter`
- **Migration path**: Update namespaces, fix nullability, update type references
- **Risk**: Build errors in API documentation configuration

### 6. HTTPS Enabled by Default
- **Impact**: MEDIUM
- **Area**: Configuration, local development, deployment
- `UseHttps` in Global Settings now defaults to `true` (was `false`)
- **Scan for**: Local dev environments without HTTPS, HTTP-only configurations
- **Migration path**: Ensure HTTPS is configured OR explicitly set `UseHttps: false`
- **Risk**: Sites that relied on HTTP may not start properly

### 7. Backoffice Authentication Tightened
- **Impact**: MEDIUM
- **Area**: Custom backoffice extensions, Management API integrations
- Following IETF RFC for browser-based apps
- All fetch requests to Management API must include `credentials: 'include'`
- Only affects backoffice client auth against Management API
- Does NOT affect API user auth or Delivery API
- **Scan for**: Custom fetch calls to Management API without `credentials: 'include'`, custom backoffice extensions making API calls
- **Migration path**: Add `credentials: 'include'` to all Management API fetch calls
- **Risk**: Custom extensions silently fail to authenticate

### 8. Removed Extension Methods
- **Impact**: LOW-MEDIUM
- **Area**: Custom C# code using Umbraco extension methods
- Removed (previously obsolete):
  - `GetAssemblyFile`
  - `ToSingleItemCollection`
  - `GenerateDataTable`, `CreateTableData`, `AddRowData`, `ChildrenAsTable` (DataTable related)
  - `RetryUntilSuccessOrTimeout`, `RetryUntilSuccessOrMaxAttempts`
  - `HasFlagAny`
  - `Deconstruct`
  - `AsEnumerable`, `ContainsKey`, `GetValue` (NameValueCollection extensions)
  - `DisposeIfDisposable`
  - `SafeCast`
  - `ToDictionary` on `object`
  - `SanitizeThreadCulture`
- **Scan for**: Any usage of these method names in custom code
- **Migration path**: Replace with standard .NET equivalents or custom implementations
- **Risk**: Build errors (compile-time, easily caught)

### 9. TipTap Import Namespace Change
- **Impact**: LOW-MEDIUM
- **Area**: Custom backoffice extensions using TipTap
- Old: `@umbraco-cms/backoffice/external/tiptap`
- New: `@umbraco-cms/backoffice/tiptap`
- **Scan for**: Import statements referencing the old path
- **Migration path**: Find and replace import paths
- **Risk**: Build errors in client-side code

### 10. Client-Side User Entities Moved
- **Impact**: LOW
- **Area**: Custom backoffice extensions
- Components moved from `user` to `current-user`:
  - `UmbCurrentUserAllowMfaActionCondition`
  - `UmbCurrentUserConfigRepository`
  - `UmbCurrentUserConfigStore`
  - `UMB_CURRENT_USER_CONFIG_STORE_CONTEXT`
- Import from `@umbraco-cms/backoffice/current-user`
- **Scan for**: Imports from `@umbraco-cms/backoffice/user` for these specific components

### 11. URL Provider Interface Changes
- **Impact**: MEDIUM for custom URL providers
- **Area**: Routing, URL generation, content preview
- `IUrlProvider` now requires `GetPreviewUrlAsync()` method and unique `Alias`
- `UrlInfo` class revamped
- **Scan for**: Custom `IUrlProvider` implementations, custom URL generation code
- **Migration path**: Implement new interface members
- **Risk**: Build errors; preview URLs broken if not updated

### 12. Section Context Changes
- **Impact**: LOW
- **Area**: Custom backoffice sections
- `UmbSectionContext.setManifest()` replaced with `manifest` property
- `ManifestSection` extends `ManifestElementAndApi` instead of `ManifestElement`
- `UmbSectionElement` extends `UmbControllerHostElement` instead of `HTMLElement`
- **Scan for**: Custom section implementations, `setManifest()` calls

### 13. Date Picker Property Editor Kind
- **Impact**: LOW-MEDIUM
- **Area**: Date picker usage in templates/code
- DateTime `Kind` changed from `UTC` to `Unspecified`
- **Scan for**: Code checking `DateTime.Kind == DateTimeKind.Utc` on date picker values
- **Migration path**: Update comparison logic

### 14. Color Picker Property Editor
- **Impact**: LOW
- **Area**: Color picker usage in templates
- Now always exposes `PickedColor` object (previously only with labels configured)
- **Scan for**: Code accessing color picker value as `string` directly
- **Migration path**: Update to use `PickedColor` object

### 15. Forms License Model Change
- **Impact**: HIGH for Forms users
- **Area**: Umbraco Forms licensing
- Forms 17 requires subscription-based license key in `appsettings.json`
- Old `.lic` file format no longer supported in Forms 17
- Existing one-off licenses can be migrated (32 months minus license age)
- **Scan for**: `.lic` files, Forms license configuration
- **Migration path**: Migrate license via Umbraco Forms product page
- **Risk**: Forms will not function without license migration

## New Features (Non-Breaking, but Relevant)
- Release Sets enabled by default (can be disabled via permissions)
- Load-balanced backoffice support improvements
- Deploy now supports Engage configuration transfers
- UI Builder extensions auto-upgrade from U17 onward
- SignalR replaces WebSocket for preview connectivity
