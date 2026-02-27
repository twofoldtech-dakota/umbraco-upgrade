# Breaking Changes: Umbraco 15 → 16

## Critical Changes

### 1. TinyMCE Removed
- **Impact**: HIGH
- **Area**: Content editing, property editors, data types
- In U15, both TinyMCE and TipTap were available as rich text editors
- In U16, only TipTap is available (TinyMCE license change to non-MIT)
- Automatic migration runs on upgrade: all TinyMCE data types → TipTap
- **Scan for**: Data types using `Umbraco.TinyMCE`, custom TinyMCE plugins, TinyMCE configuration in appsettings
- **Migration path**: Allow automatic migration OR install third-party TinyMCE package before upgrade to disable migration
- **Risk**: Content formatting differences between TinyMCE and TipTap output; custom toolbar buttons lost

### 2. Async Package Migrations (Binary-Incompatible)
- **Impact**: HIGH for packages, MEDIUM for custom code
- **Area**: Database migrations, package migrations
- New base class for package migrations supporting async
- Source-compatible but binary-incompatible change
- Code built against U15 calling base class helper methods (e.g., `TableExists`) will throw "method missing" at runtime on U16
- **Scan for**: Classes inheriting from migration base classes, calls to `TableExists`, `AddColumn`, etc.
- **Migration path**: Recompile all migration code against U16 packages
- **Risk**: Runtime exceptions if packages not recompiled

### 3. Examine Registered via Composer
- **Impact**: MEDIUM
- **Area**: Search, indexing, Examine customizations
- Examine component registration moved to a composer (`AddExamineComposer`)
- Custom Examine code registered via composers is no longer guaranteed to run after core setup
- **Scan for**: Custom Examine index configurations, custom composers touching Examine, `IExamineManager` registrations
- **Migration path**: Add `[ComposeAfter(typeof(Umbraco.Cms.Infrastructure.Examine.AddExamineComposer))]` to custom composers
- **Risk**: Custom search indexes not properly configured at startup

### 4. Webhooks Filtering Update
- **Impact**: LOW-MEDIUM
- **Area**: Webhook integrations
- Webhooks can now filter on specific content types
- Interface changes to webhook-related services
- **Scan for**: Custom webhook implementations, `IWebhookService` usage

### 5. Extension System Updates
- **Impact**: LOW-MEDIUM
- **Area**: Backoffice extensions
- Various manifest and extension registration updates
- Continued evolution of the Lit-based backoffice framework
- **Scan for**: Custom backoffice extensions, manifest files, extension registrations

## Dependency Updates
- General NuGet package updates
- Node/npm dependency updates for client-side
- No major framework version jump (still .NET 9)

## Migration Notes
- U15 → U16 is an STS-to-STS upgrade
- Automatic database migrations run on startup
- Recommended: Enable unattended upgrades OR use maintenance mode for controlled upgrade
- Always back up database before upgrade
