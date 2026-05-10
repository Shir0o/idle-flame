# Documentation

Internal docs for **Zenith Zero: Idle Descent**.

## Design

Sequential design docs that drove each system overhaul. Each was written as a design-only proposal, then implemented in a follow-up commit. Read in order to understand the system's evolution.

Each doc is paired: a Markdown source for in-editor reading, and an HTML version with the same content plus inline SVG illustrations for richer browser viewing.

| # | Doc | Topic | What landed |
|---|---|---|---|
| 1 | [Skill Tree v1 — From Pool to Tree](design/SKILL_TREE_V1.md) · [html](design/SKILL_TREE_V1.html) | Foundation pass. Catalog consolidation (127 → 13), anti-snowball offer weight curve, six pair synergies, starter / specialist / capstone tier gates, level-5 evolutions. Layer C ("fusions") deferred. | `feat: overhaul skill system with catalog consolidation, dynamic weights, synergies, and branching evolutions` |
| 2 | [Skill Tree v2 — The Three Paths](design/SKILL_TREE_V2.md) · [html](design/SKILL_TREE_V2.html) | Promote the EDGE / DAEMON / HEX trio into a primary organizing layer. Path tiers, Fusion Forms (v1's deferred Layer C), Heretic Cants, Sutras, Awakening, Sigil Matrix, Codex. | `feat: implement Skill Tree v2 with Paths, Tiers, Fusions, Codex, and Heretic Cants` |
| 3 | [Skill Tree v3 — Depth Per Skill](design/SKILL_TREE_V3.md) · [html](design/SKILL_TREE_V3.html) | Multiply per-pick variety without new archetypes. Inflections (Hades-style mini-mods), Triads (3-archetype synergies), Path Signatures (Stance / Bandwidth / Cinder). Plus Sutra perks at 5/10/25 and near-orbit offer weighting. | `feat: implement Skill Tree v3 with Inflections, Triads, and Path Signatures` (+ rare-tier expansion follow-up) |
| 4 | [Floors v1 — The Descent Has Texture](design/FLOORS_V1.md) · [html](design/FLOORS_V1.html) | Give the build variety something interesting to push against. Three-phase floors, twelve floor modifiers, five named bosses, six new enemy archetypes. | `feat: implement Floors v1 wave structure, modifiers, and boss scaffolding` |
| 5 | [Floors v2 — Finishing the Texture](design/FLOORS_V2.md) · [html](design/FLOORS_V2.html) | Polish pass closing six v1 gaps: tiered boss rewards, boss telegraph + arena dim, first-encounter counter tips, Codex Bestiary + Crucibles tabs, missing modifier wiring, post-boss reward room. | `feat: implement Floors v1.5 polish pass` (commit naming predates the v2 rename) |
| 6 | [Floors v3 — Past the Architect](design/FLOORS_V3.md) · [html](design/FLOORS_V3.html) | Next-step pass turning the v2 frame into a replayable one: Architect Echoes (Endless mode F26+), reward rooms every 5 floors with an expanded boon pool, in-run Codex slate, run summary recap, Daily Descent seeded mode. | *not yet implemented* |

## Conventions used in these docs

- **Voice** — neon cyberpunk · katana · magitech. Avoid generic fantasy terms (school, perk, talent, prestige token); prefer the established vocabulary (path, sutra, awakening, sigil, cant, inflection, triad, fusion).
- **Structure** — every doc has §0 *Why this exists*, a body of mechanics, a §X *Build order* with day estimates, a *Player-incentive checklist*, an *avoids* section, and *open questions* for playtesting.
- **Design-only** — these docs propose, they do not patch. Implementation lands in separate commits referenced in the table above.

## Where things live in code

| System | Primary file(s) |
|---|---|
| Paths, archetypes, evolutions, fusions, heretic cants | [`lib/game/state/skill_catalog.dart`](../lib/game/state/skill_catalog.dart) |
| Inflections | [`lib/game/state/inflection_catalog.dart`](../lib/game/state/inflection_catalog.dart) |
| Triads | [`lib/game/state/triad_catalog.dart`](../lib/game/state/triad_catalog.dart) |
| Run state, path tiers, signatures, floor phases, modifiers, weights | [`lib/game/state/game_state.dart`](../lib/game/state/game_state.dart) |
| Persistent meta (sutras, awakening, codex) | [`lib/game/state/meta_state.dart`](../lib/game/state/meta_state.dart) |
| Path tier visual effects (Spectral Katana, Satellite Uplink, Ward Circle, Trinity rings) | [`lib/game/components/path_benefits.dart`](../lib/game/components/path_benefits.dart) |
| Enemies, bosses, enemy mechanics | [`lib/game/components/enemy.dart`](../lib/game/components/enemy.dart) |
| Wave / phase / boss spawning | [`lib/game/components/enemy_spawner.dart`](../lib/game/components/enemy_spawner.dart) |
| HUD (phase chip, modifier chips, picker, sigil matrix embed) | [`lib/ui/hud.dart`](../lib/ui/hud.dart) |
| Sigil Matrix UI | [`lib/ui/sigil_matrix.dart`](../lib/ui/sigil_matrix.dart) |
| Meta screen + Codex tabs | [`lib/ui/meta_screen.dart`](../lib/ui/meta_screen.dart) |
