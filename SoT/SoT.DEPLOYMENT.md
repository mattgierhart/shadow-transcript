---
version: 2.0
purpose: Source of Truth for deployment configuration, environments, secrets inventory, procedures, runbooks, and monitoring.
id_prefix: DEP-XXX, RUN-XXX, MON-XXX, SEC-XXX
last_updated: YYYY-MM-DD
authority: This is a SoT file - IDs here are referenced by PRD.md, EPICs, and operations docs
---
<!-- SECTION: template-structure -->

# Deployment (SoT File)

> **Purpose**: Deployment configuration, secrets inventory, operational runbooks, and monitoring rules.
> **ID Prefixes**: DEP-XXX (Deployment), RUN-XXX (Runbooks), MON-XXX (Monitoring), SEC-XXX (Secrets)
> **Status**: Active SoT file
> **Cross-References**: Referenced by PRD.md v0.7/v0.8, EPICs, SoT.TESTING.md
> **Note**: GTM-XXX (Go-to-Market) IDs live in PRD.md v0.9 section

---

## Navigation by Category

**Environments** (ENV-001 to ENV-099):
- See [SoT.TECHNICAL_DECISIONS.md](SoT.TECHNICAL_DECISIONS.md) for ENV-XXX IDs

**Secrets Inventory** (SEC-001 to SEC-099):
- [SEC-001](#sec-001-secret-name) - {Secret name}

**Deployment Procedures** (DEP-001 to DEP-099):
- [DEP-001](#dep-001-procedure-name) - {Procedure name}
- [DEP-002](#dep-002-diarize-sidecar-bundle--codesign) - Diarize Sidecar Bundle + Codesign (EPIC-04b)

**Operational Runbooks** (RUN-001 to RUN-099):
- [RUN-001](#run-001-runbook-name) - {Runbook name}

**Monitoring Rules** (MON-001 to MON-099):
- [MON-001](#mon-001-metric-name) - {Metric name}

---

## Environments

| ID | Environment | Platform | URL | Branch Trigger |
|----|-------------|----------|-----|----------------|
| ENV-001 | Production | [Platform] | [URL] | main |
| ENV-002 | Preview | [Platform] | [Pattern] | Pull requests |
| ENV-003 | Development | Local | localhost:[port] | N/A |

> **Note**: ENV-XXX IDs are defined in [SoT.TECHNICAL_DECISIONS.md](SoT.TECHNICAL_DECISIONS.md). This table provides a deployment-focused view.

---

## Secrets Inventory

Track all secrets required for deployment. **Do not store actual values here** — only metadata.

| ID | Secret Name | Environment(s) | Storage Location | Owner | Last Rotated |
|----|-------------|----------------|------------------|-------|--------------|
| SEC-001 | DATABASE_URL | Production, Preview | [Platform secrets] | [Name] | YYYY-MM-DD |
| SEC-002 | API_KEY | All | [Platform secrets] | [Name] | YYYY-MM-DD |
| SEC-003 | [Name] | [Env] | [Location] | [Owner] | YYYY-MM-DD |

### Secret Categories

**Web Secrets**
- Database connection strings
- Third-party API keys
- Authentication secrets (JWT, OAuth)
- Analytics/monitoring keys

**Mobile Secrets** (if applicable)
- Code signing credentials (certificates, provisioning profiles)
- App store API keys
- Push notification credentials
- Keystore passwords (Android)

**Shared Secrets**
- Secrets used by both web and mobile
- Note sync requirements between platforms

### SEC-001: {Secret Name}

**ID**: SEC-001
**Category**: Database | API | Authentication | Signing
**Status**: Active | Deprecated | Planned
**Environments**: Production, Preview, Development
**Storage**: [Platform secrets manager]
**Owner**: [Name/Team]
**Last Rotated**: YYYY-MM-DD

#### Purpose

{What this secret is used for.}

#### Rotation Procedure

1. Generate new secret value in source system
2. Update secret in [storage location]
3. Trigger redeployment if needed
4. Verify application works with new secret
5. Revoke old secret value

#### Related IDs

- [DEP-XXX](#dep-xxx-procedure-name) - {Deployment using this secret}
- [RUN-XXX](#run-xxx-runbook-name) - {Runbook for rotation}

---

## CI/CD Configuration

### Pipeline Overview

```
[Trigger] → [Quality Checks] → [Build] → [Deploy] → [Verify]
```

### Workflow Files

| Workflow | Trigger | Purpose | File Location |
|----------|---------|---------|---------------|
| CI | Push, PR | Lint, test, typecheck | .github/workflows/ci.yml |
| Deploy Web | Merge to main | Production deployment | [Platform-managed or workflow] |
| Deploy Mobile | Version tag | App store submission | .github/workflows/mobile.yml |

### Branch Protection Rules

| Rule | Enabled | Notes |
|------|---------|-------|
| Require PR before merge | Yes/No | |
| Require status checks | Yes/No | Checks: [list] |
| Require up-to-date branch | Yes/No | |
| Require approvals | Yes/No | Count: [n] |

---

## Platform-Specific Configuration

### Web Deployment

| Setting | Value |
|---------|-------|
| Platform | [e.g., Vercel, Netlify, AWS] |
| Framework preset | [e.g., Next.js, Vite] |
| Build command | [command] |
| Output directory | [path] |
| Node version | [version] |

### Mobile Deployment (if applicable)

| Setting | iOS | Android |
|---------|-----|---------|
| Signing approach | [Manual/Managed/Automated] | [Keystore location] |
| Beta distribution | [TestFlight/Other] | [Play Store Internal/Other] |
| Production track | App Store | Play Store Production |
| Build automation | [Tool] | [Tool] |

---

## Setup Checklist

Use this checklist when initializing deployment for a new product.

### Initial Setup
- [ ] Create hosting account/project
- [ ] Connect repository to hosting platform
- [ ] Configure environment variables
- [ ] Set up branch protection rules
- [ ] Verify preview deployments work

### Mobile Setup (if applicable)
- [ ] Create app store accounts (Apple Developer, Google Play Console)
- [ ] Generate code signing credentials
- [ ] Store signing credentials securely
- [ ] Configure build automation
- [ ] Test beta deployment flow
- [ ] Test production deployment flow

### Verification
- [ ] Push to feature branch → Preview deployment works
- [ ] Merge to main → Production deployment works
- [ ] All secrets are documented in inventory (not values, just metadata)
- [ ] Team members can deploy without tribal knowledge

---

## DEP-001: {Procedure Name}

**ID**: DEP-001
**Category**: Infrastructure | Application | Database
**Status**: Active | Deprecated | Planned
**Created**: YYYY-MM-DD

### Purpose

{What this deployment procedure accomplishes.}

### Steps

1. **Prepare**: {Preparation step}
2. **Deploy**: {Deployment step}
3. **Verify**: {Verification step}

### Rollback

{How to rollback if deployment fails.}

### Related IDs

- [TEST-XXX](SoT.TESTING.md#test-xxx) - {Deployment validation test}
- [MON-XXX](#mon-xxx-metric-name) - {Metrics to watch}
- [SEC-XXX](#sec-xxx-secret-name) - {Secrets required}

---

## DEP-002: Diarize Sidecar Bundle + Codesign

**ID**: DEP-002
**Category**: Application
**Status**: Active (EPIC-04b, 2026-05-09)
**Created**: 2026-05-09

### Purpose

Embed the EPIC-04a `--onedir` PyInstaller bundle inside `TranscriptShadow.app`
at `Contents/Resources/diarize/` and codesign every binary in the tree
bottom-up so the sandboxed parent can spawn the child without dyld
refusing to load unsigned `.dylib` / `.so` files.

This is the contract the eventual notarization step (deferred to a
release-prep EPIC) will read.

### Entitlements matrix

**Parent app** — `TranscriptShadow/TranscriptShadow.entitlements`:

| Entitlement | Reason | Source |
|---|---|---|
| `com.apple.security.app-sandbox` | App sandbox | EPIC-01 |
| `com.apple.security.device.audio-input` | Mic capture | EPIC-01 |
| `com.apple.security.network.client` | WhisperKit model download | EPIC-01 |
| `com.apple.security.cs.disable-library-validation` | PyInstaller bootloader loads `.dylib` / `.so` not signed by our Team ID | EPIC-04b |
| `com.apple.security.cs.allow-unsigned-executable-memory` | CPython bytecode + ctypes paths | EPIC-04b |
| `com.apple.security.cs.allow-jit` | torch MPS Metal compilers (defensive) | EPIC-04b |
| `com.apple.security.files.user-selected.read-only` | NSOpenPanel audio file picker | EPIC-04b |
| `com.apple.security.files.bookmarks.app-scope` | Persist security-scoped bookmarks | EPIC-04b |

**Child binary** — `TranscriptShadow/Diarization/diarize.entitlements`:

| Entitlement | Value | Reason |
|---|---|---|
| `com.apple.security.app-sandbox` | true | Inherit sandbox |
| `com.apple.security.inherit` | true | Pull sandbox from parent |

**Critical**: NO other entitlement may be set on the child. Anything else
(notably the auto-injected `get-task-allow` in Debug builds) crashes
`_libsecinit_appsandbox` on launch.

**Debug-only override** — `TranscriptShadow/TranscriptShadow.Debug.entitlements`:

Empty `dict`. Disables sandbox for the test host so the integration
test suite can exec fake `diarize` shell scripts. Release uses the
production entitlements above.

### Codesign sequence (Run Script Build Phase)

`project.yml` declares a `postBuildScripts` Run Script that fires after
the build target produces the `.app` bundle:

1. **Skip if no bundle**: If `sidecar/dist/diarize/` does not exist:
   - Debug → log a note and exit 0
   - Release → fail loudly so the bundle is always present before archive
2. **Copy**: `rsync -a --delete sidecar/dist/diarize/ → Resources/diarize/`
3. **Bottom-up sign**: every `.dylib` / `.so` under
   `Resources/diarize/_internal/` gets `codesign --force --options=runtime
   <timestamp> -s "$IDENTITY"`. Order matters: signers depend on signed
   children. NEVER `--deep` at sign time (deprecated since macOS 13;
   notarization-rejection trigger).
4. **Sign the inner binary**: `Resources/diarize/diarize` gets the same
   flags PLUS `--entitlements diarize.entitlements`. This overwrites
   any auto-injected entitlements (notably `get-task-allow` in Debug).
5. **Verify**: `codesign --verify --deep --strict --verbose=2`. `--deep`
   is OK on `verify`; only sign-time `--deep` is deprecated.

`$EXPANDED_CODE_SIGN_IDENTITY` resolves to `-` for ad-hoc Debug signing
and to the developer cert SHA-1 for Release. `--timestamp` is omitted in
Debug (no internet round-trip needed).

### Procedure (release-prep)

```bash
# 1. Build the PyInstaller bundle (multi-GB, ~5 min, release-only)
cd sidecar
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pyinstaller diarize.spec   # produces sidecar/dist/diarize/

# 2. Archive the .app — the postBuildScripts Run Script copies the
#    bundle into Resources/diarize/ and signs everything.
xcodebuild archive -scheme TranscriptShadow -archivePath build/TS.xcarchive

# 3. Verify the embedded child has ONLY app-sandbox + inherit
codesign -dvvv --extract-certificates --requirements - \
    build/TS.xcarchive/Products/Applications/TranscriptShadow.app/Contents/Resources/diarize/diarize
```

### Rollback

If a release archive fails the codesign verify step, the build fails
loudly. Don't ship a partially-signed bundle. Common causes:

- `--deep` accidentally introduced at sign time — search the Run Script
  and remove.
- A non-inherit entitlement on the child — re-inspect the entitlements
  file and the post-sign output.
- Bash-only syntax in the Run Script — phases run `/bin/sh`, not bash.

### Related IDs

- [API-102](SoT.API_CONTRACTS.md#api-102-diarization-sidecar-cli) - Subprocess CLI contract
- [INT-102](SoT.INTEGRATIONS.md#int-102-pyannote-diarization) - pyannote integration
- [ARC-002](SoT.TECHNICAL_DECISIONS.md#arc-002-python-sidecar-for-diarization) - Sidecar architecture
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Sandbox preserves local-only invariant

---

## RUN-001: {Runbook Name}

**ID**: RUN-001
**Category**: Incident Response | Maintenance | Recovery
**Status**: Active | Deprecated
**Created**: YYYY-MM-DD

### When to Use

{Trigger conditions for this runbook.}

### Steps

1. **Assess**: {Assessment step}
2. **Mitigate**: {Mitigation step}
3. **Resolve**: {Resolution step}

### Related IDs

- [MON-XXX](#mon-xxx-metric-name) - {Alert triggering this runbook}

---

## Runbook: Common Operations

### Rotate a Secret
1. Generate new secret value in source system
2. Update secret in [storage location]
3. Trigger redeployment if needed
4. Update "Last Rotated" in secrets inventory
5. Revoke old secret value

### Rollback Production
1. [Platform-specific rollback steps]
2. Verify rollback successful
3. Document incident

### Add New Environment Variable
1. Add to [storage location] for each environment
2. Update secrets inventory
3. Update application code to use variable
4. Deploy and verify

---

## MON-001: {Metric Name}

**ID**: MON-001
**Category**: Performance | Availability | Business
**Status**: Active | Planned
**Created**: YYYY-MM-DD

### Definition

**What**: {What is being measured}
**Thresholds**: Warning: {value} | Critical: {value}

### Related IDs

- [RUN-XXX](#run-xxx-runbook-name) - {Runbook if threshold breached}
- [BR-XXX](SoT.BUSINESS_RULES.md#br-xxx) - {SLA or requirement}

<!-- /SECTION: template-structure -->

---
<!-- CUSTOMIZABLE: entries -->

## Deprecated Entries

### DEP-XXX: {Name} [DEPRECATED]

**Status**: Deprecated (YYYY-MM-DD)
**Replacement**: [DEP-YYY](#dep-yyy-name) | None
**Reason**: {Why deprecated}

<!-- /CUSTOMIZABLE: entries -->

---

## Update Protocol

### When to Add New IDs

1. **SEC-XXX**: New secret or credential required for deployment
2. **DEP-XXX**: New deployment procedure or environment
3. **RUN-XXX**: New incident response or maintenance procedure
4. **MON-XXX**: New metric, alert, or dashboard

### Bidirectional Reference Checklist

When adding a new SEC/DEP/RUN/MON-XXX:

- [ ] Update SoT.TESTING.md if deployment has tests
- [ ] Update EPIC Section 2 "Context & IDs" list
- [ ] Link runbooks to monitoring alerts
- [ ] Link secrets to deployments that use them
- [ ] Update SoT.UNIQUE_ID_SYSTEM.md registry if maintained

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Added Secrets Inventory, CI/CD Configuration, Platform Configuration sections | [Name] |
| YYYY-MM-DD | Initial deployment configuration | [Name] |

---

*End of SoT.DEPLOYMENT.md - Authoritative source for DEP-XXX, RUN-XXX, MON-XXX, SEC-XXX IDs*
