# Coding Standards

## Traceability Protocol (MANDATORY)

Every major code unit must declare which ID it implements.

```swift
// @implements BR-102 (No persistent audio storage)
// @see API-301
// @verifies BR-102   (on the test that checks it)
final class DefaultTempAudioCleanup { ... }
```

These tags are not just comments — they are the bridge edges (`implements` / `verifies` / `references`) linking each code unit to the spec ID it realizes. When this repo adopts the Development Graph emitter, they will be harvested into `status/devgraph.json` and readiness will measure build-vs-blueprint (`implementation_coverage`) from them; the schema is documented in [`docs/DEVELOPMENT_GRAPH.md`](../../docs/DEVELOPMENT_GRAPH.md). Untagged code shows up as an orphan node — a context leak — so tag now even though the emitter is deferred.

- **Tests First**: Create/Update tests (`TEST-`) for every feature.
- **No Secrets**: Never commit credentials. (HF token handling: see SEC- entries in `SoT/SoT.DEPLOYMENT.md`.)
- **Small Commits**: Group changes by ID/Feature.
- **Tag Everything**: Every major unit carries `@implements`; tests carry `@verifies`. No orphan code.
