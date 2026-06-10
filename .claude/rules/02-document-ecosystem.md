# Document Ecosystem

The methodology uses a layered document structure:

| Layer | Files | Purpose |
|-------|-------|---------|
| **Navigation** | README.md | Entry point, dashboard, current status |
| **Strategy** | PRD.md | Requirements evolving v0.1→v1.0 |
| **Execution** | epics/EPIC-XX.md | Active work, session handoffs |
| **Knowledge** | SoT/*.md | Durable specs with unique IDs |
| **Scratchpad** | temp/*.md | Ephemeral notes, harvested to SoT |

**ID Ownership** (see `.claude/domain-profile.yaml` for the full registry, including this repo's local additions):
- SoT files own: BR, UJ, PER, SCR, API, DBT, TEST, DEP, RUN, MON, SEC, CFD, DES, TECH, ARC, ENV, INT, LL
- PRD.md owns: FEA (v0.3), RISK (v0.5), GTM (v0.9 — unused here; pricing/GTM deliberately skipped for this personal utility)
- README.md owns: KPI metrics

**Local conventions**: SEC- (secrets inventory, in SoT.DEPLOYMENT.md) and ENV- (environment setup, in SoT.TECHNICAL_DECISIONS.md) are local additions. Several files use sub-series numbering (API-001/101/201/301 per pipeline stage) — a navigation aid only; IDs are never renumbered.

**Cross-Reference Rule**: Every ID should link to related IDs. This creates a knowledge graph that agents can traverse.
