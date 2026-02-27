# Package Compatibility Reference

## Umbraco Core Packages

| Package | U15 Version | U16 Version | U17 Version | Notes |
|---------|------------|------------|------------|-------|
| Umbraco.Cms | 15.x | 16.x | 17.x | Major version matches Umbraco version |
| Umbraco.Cms.DevelopmentMode.Backoffice | N/A | N/A | 17.x | NEW in U17 — required for InMemoryAuto models |
| Umbraco.Forms | 15.x | 16.x | 17.x | License model changes in 17 (.lic → subscription key) |
| Umbraco.Deploy | 15.x | 16.x | 17.x | Now supports Engage config transfers in 17 |
| Umbraco.Commerce | 15.x | 16.x | 17.x | |
| Umbraco.Workflow | 15.x | 16.x | 17.x | Settings moved from /workflow to /settings in 17 |
| Umbraco.Cms.Search | N/A | experimental | 17.x | New external search package (replaces built-in Examine option) |

## Framework Dependencies

| Dependency | U15 | U16 | U17 | Migration Notes |
|-----------|-----|-----|-----|----------------|
| .NET | 9.0 | 9.0 | 10.0 | Major framework update required |
| NPoco | 5.7.x | 5.7.x | 6.1.0 | Breaking API changes in 6.x |
| Swashbuckle | 6.x | 6.x | 10.0.1 | Namespace and type changes |
| TinyMCE | Included | Removed | Removed | Removed in U16 due to license change |
| TipTap | Included | Default | Default | Sole RTE from U16+ |

## Common Third-Party Packages

When auditing, check each third-party package for .NET 10 and U17 compatibility.

### Known Compatible (verify latest version)
- uSync (check for U17-compatible version)
- Contentment (check for U17-compatible version)
- Our.Umbraco.Community.* packages (check individually)

### Requires Investigation
Any package not explicitly listed needs manual verification:
1. Check the package's NuGet page for supported Umbraco versions
2. Check the package's GitHub repo for U17 branches or releases
3. If no U17 support, assess: can it be replaced, forked, or removed?

## Audit Checklist for Package Compatibility

For each NuGet package in the solution:

```
[ ] Package name and current version
[ ] Is there a U17-compatible version available?
[ ] Does the U17 version require .NET 10?
[ ] Are there breaking API changes between current and U17 version?
[ ] Is the package actively maintained?
[ ] If no U17 version: can the package be replaced or removed?
[ ] License changes (especially Umbraco Forms)?
```

For each npm package in backoffice extensions:

```
[ ] Package name and current version
[ ] Is there a U17-compatible version available?
[ ] Does it depend on removed/changed Umbraco client APIs?
```

## Version Upgrade Strategy

### Direct Upgrade (15 → 17)
Not officially supported as a single jump. The recommended path:
- 15 → 16 → 17 (stepping through each STS)
- OR if on an LTS, direct LTS-to-LTS is supported (13 → 17)

Since U15 is STS (not LTS), the safest path is:
1. U15 → U16 (apply U16 breaking changes)
2. U16 → U17 (apply U17 breaking changes + .NET 10)

However, in practice many teams do update all NuGet packages to U17 at once and address all breaking changes together. This works if you're methodical about the breaking changes from both versions.

### Recommended Approach
For enterprise projects with significant customization:
- Step through 15 → 16 → 17
- Test at each step
- This isolates breaking changes and makes debugging easier

For simpler projects with minimal customization:
- Direct 15 → 17 NuGet update
- Address all breaking changes at once
- Faster but harder to debug issues
