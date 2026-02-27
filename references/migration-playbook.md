# Migration Playbook

Common migration recipes for upgrading Umbraco 15 → 17. Each recipe covers a specific breaking change area with before/after code examples and step-by-step instructions.

## Table of Contents
1. [Target Framework Update](#1-target-framework-update)
2. [TinyMCE to TipTap Migration](#2-tinymce-to-tiptap)
3. [Models Builder Mode Change](#3-models-builder-mode)
4. [UTC Date Handling](#4-utc-date-handling)
5. [Async Package Migrations](#5-async-package-migrations)
6. [Examine Composer Ordering](#6-examine-composer-ordering)
7. [Removed Extension Methods](#7-removed-extension-methods)
8. [NPoco 6.x Updates](#8-npoco-6x-updates)
9. [Swashbuckle 10.x Updates](#9-swashbuckle-10x-updates)
10. [Backoffice Extension Updates](#10-backoffice-extension-updates)
11. [IUrlProvider Changes](#11-iurlprovider-changes)
12. [Forms License Migration](#12-forms-license-migration)
13. [HTTPS Default Configuration](#13-https-default)
14. [Backoffice Auth Credentials](#14-backoffice-auth-credentials)

---

## 1. Target Framework Update

### Steps
1. Update `global.json` SDK version to .NET 10
2. Update all `.csproj` files:

**Before:**
```xml
<TargetFramework>net9.0</TargetFramework>
```

**After:**
```xml
<TargetFramework>net10.0</TargetFramework>
```

3. Update Docker base images if applicable
4. Update CI/CD pipelines to use .NET 10 SDK
5. Run `dotnet restore` and fix any package incompatibilities
6. Run `dotnet build` and fix compilation errors

---

## 2. TinyMCE to TipTap

### Automatic Migration (U16)
Umbraco 16 auto-migrates TinyMCE data types to TipTap on upgrade. The stored RTE content (HTML) is preserved but the editor configuration changes.

### What to Check Post-Migration
- Custom TinyMCE plugins: These will NOT migrate. Rebuild as TipTap extensions.
- Custom toolbar configurations: Review and recreate in TipTap
- CSS that targeted TinyMCE's HTML output structure
- JavaScript that interacted with TinyMCE's API

### TipTap Extension Pattern
If you had custom TinyMCE plugins, create TipTap extensions:

```typescript
// Custom TipTap extension example
import { Extension } from '@umbraco-cms/backoffice/tiptap'; // Note: new import path in U17

export const MyCustomExtension = Extension.create({
  name: 'myCustomExtension',
  // ... extension configuration
});
```

### Content Verification
After migration, spot-check content pages that used RTE heavily:
- Tables formatting
- Custom styles/classes
- Embedded media
- Links and anchors
- Block-level content

---

## 3. Models Builder Mode

### If Using InMemoryAuto

**Add the new package:**
```xml
<PackageReference Include="Umbraco.Cms.DevelopmentMode.Backoffice" Version="17.*" />
```

**Remove obsolete flags from .csproj:**
```xml
<!-- REMOVE these lines -->
<RazorCompileOnBuild>false</RazorCompileOnBuild>
<RazorCompileOnPublish>false</RazorCompileOnPublish>
```

### If Using ModelsMode Enum
Replace enum usage with string constants:

**Before:**
```csharp
if (modelsMode == ModelsMode.InMemoryAuto)
```

**After:**
```csharp
if (modelsMode == Constants.ModelsBuilder.ModelsModes.InMemoryAuto)
```

### Recommended: Consider Switching to SourceCodeAuto
`SourceCodeAuto` doesn't require the dev mode package and enables Hot Reload. For teams not editing templates in the backoffice, this is the better option for U17.

---

## 4. UTC Date Handling

### Configuration
The migration runs automatically. Optionally configure:

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

### Custom Code Updates

**Before (server local time):**
```csharp
var publishDate = content.UpdateDate; // Was server local time
var formatted = publishDate.ToString("g"); // Displayed as-is
```

**After (UTC):**
```csharp
var publishDate = content.UpdateDate; // Now UTC
var localTime = TimeZoneInfo.ConvertTimeFromUtc(publishDate, localTimeZone);
var formatted = localTime.ToString("g");
```

**Custom SQL queries:**
```csharp
// BEFORE: comparing with DateTime.Now
var recent = Database.Fetch<MyEntity>("WHERE createDate > @0", DateTime.Now.AddDays(-7));

// AFTER: comparing with DateTime.UtcNow
var recent = Database.Fetch<MyEntity>("WHERE createDate > @0", DateTime.UtcNow.AddDays(-7));
```

### Date Picker Kind Change
```csharp
// BEFORE: date picker returned Kind = UTC
var date = content.Value<DateTime>("myDate");
// date.Kind was DateTimeKind.Utc

// AFTER: date picker returns Kind = Unspecified
var date = content.Value<DateTime>("myDate");
// date.Kind is now DateTimeKind.Unspecified
// Do NOT assume UTC — treat as user-entered local date
```

---

## 5. Async Package Migrations

### Recompile Against U16+ Packages
The change is source-compatible but binary-incompatible. Simply recompiling fixes it.

If your migrations call base class helpers:
```csharp
public class MyMigration : MigrationBase
{
    protected override void Migrate()
    {
        if (TableExists("myTable")) // This call is binary-incompatible
        {
            // ...
        }
    }
}
```

Recompile against U16/U17 NuGet packages. No code changes needed if only using base class methods.

---

## 6. Examine Composer Ordering

**Before (U15):**
```csharp
public class MyExamineComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        // Custom Examine configuration
    }
}
```

**After (U16+):**
```csharp
[ComposeAfter(typeof(Umbraco.Cms.Infrastructure.Examine.AddExamineComposer))]
public class MyExamineComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        // Custom Examine configuration — now guaranteed to run after core setup
    }
}
```

---

## 7. Removed Extension Methods

Each removed method and its replacement:

| Removed Method | Replacement |
|---------------|-------------|
| `GetAssemblyFile` | Use `Assembly.Location` or `Assembly.GetName()` |
| `ToSingleItemCollection` | `new[] { item }` or `new List<T> { item }` |
| `GenerateDataTable` / `ChildrenAsTable` | Use `IContentService` queries + manual mapping |
| `RetryUntilSuccessOrTimeout` | Use Polly or custom retry loop |
| `RetryUntilSuccessOrMaxAttempts` | Use Polly or custom retry loop |
| `HasFlagAny` | `(flags & targetFlags) != 0` |
| `Deconstruct` | Use C# built-in deconstruction |
| `AsEnumerable` (NameValueCollection) | `collection.AllKeys.Select(k => ...)` |
| `ContainsKey` (NameValueCollection) | `collection.AllKeys.Contains(key)` |
| `GetValue` (NameValueCollection) | `collection[key]` |
| `DisposeIfDisposable` | `(obj as IDisposable)?.Dispose()` |
| `SafeCast` | `obj as T` or pattern matching |
| `ToDictionary` (object) | Reflection-based or serialize/deserialize |
| `SanitizeThreadCulture` | Typically not needed; set culture explicitly |

---

## 8. NPoco 6.x Updates

NPoco 6 has several breaking changes. Common patterns:

### Namespace changes
Check for any NPoco-specific using statements and update if needed.

### API Changes
Verify all custom repository code compiles against NPoco 6. Key areas:
- `Database.Fetch<T>()` signatures
- `Database.Query<T>()` signatures
- Transaction handling
- Mapper configurations

Run full compilation and fix errors. The specific breaks depend on which NPoco APIs your code uses.

---

## 9. Swashbuckle 10.x Updates

### Common Changes
- Namespace: `Swashbuckle.AspNetCore.*` — some sub-namespaces renamed
- Nullability: Many parameters now non-nullable
- Types: Some configuration types changed

Fix compilation errors after NuGet update. Check:
- `AddSwaggerGen()` configuration
- Custom `IOperationFilter` implementations
- Custom `IDocumentFilter` implementations

---

## 10. Backoffice Extension Updates

### TipTap Import Path (U17)
```typescript
// BEFORE
import { Editor } from '@umbraco-cms/backoffice/external/tiptap';

// AFTER
import { Editor } from '@umbraco-cms/backoffice/tiptap';
```

### Current User Imports (U17)
```typescript
// BEFORE
import { UmbCurrentUserConfigStore } from '@umbraco-cms/backoffice/user';

// AFTER
import { UmbCurrentUserConfigStore } from '@umbraco-cms/backoffice/current-user';
```

### Section Changes (U17)
```typescript
// BEFORE
this.setManifest(manifest);
// Extending HTMLElement

// AFTER
this.manifest = manifest;
// Extend UmbControllerHostElement instead
```

---

## 11. IUrlProvider Changes

**Before:**
```csharp
public class MyUrlProvider : IUrlProvider
{
    public IEnumerable<UrlInfo> GetOtherUrls(int id, Uri current)
    {
        // ...
    }
}
```

**After:**
```csharp
public class MyUrlProvider : IUrlProvider
{
    public string Alias => "myUrlProvider"; // NEW: required alias

    public IEnumerable<UrlInfo> GetOtherUrls(int id, Uri current)
    {
        // ...
    }

    public Task<UrlInfo?> GetPreviewUrlAsync(IPublishedContent content, string culture) // NEW
    {
        // Return preview URL or null
        return Task.FromResult<UrlInfo?>(null);
    }
}
```

---

## 12. Forms License Migration

### Steps
1. Go to Umbraco Forms product page
2. Select "I want to migrate my forms license to subscription-based"
3. Receive subscription key (time credit = 32 months minus license age)
4. Add to appsettings.json:

```json
{
  "Umbraco": {
    "Forms": {
      "LicenseKey": "your-subscription-key-here"
    }
  }
}
```

5. Remove old `.lic` file from the project
6. If on Umbraco Cloud: license auto-migrates, no action needed

---

## 13. HTTPS Default

If you need HTTP (e.g., behind a reverse proxy handling TLS):

```json
{
  "Umbraco": {
    "CMS": {
      "Global": {
        "UseHttps": false
      }
    }
  }
}
```

---

## 14. Backoffice Auth Credentials

For all custom fetch calls to Management API:

**Before:**
```typescript
const response = await fetch('/umbraco/management/api/v1/my-endpoint');
```

**After:**
```typescript
const response = await fetch('/umbraco/management/api/v1/my-endpoint', {
  credentials: 'include'
});
```

Extensions built with the HQ package starter template are NOT affected (it includes credentials by default).
