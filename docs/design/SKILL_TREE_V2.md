# Skill Tree v2 — The Three Paths

*Next-stage design for the skill system in **Zenith Zero: Idle Descent**.*
*Maintains the established vibe: neon cyberpunk · katana · magitech.*

---

## 0. Why this exists

The skill system is the entire game. There is no map, no narrative arm, no gear loop. Every minute a player spends with the build is a minute spent with the skill picker. So the picker has to do four jobs at once:

1. **Identity** — give the player a build that feels like *theirs*.
2. **Discovery** — leave things to find: hidden cants, named hybrids, "wait, that worked?" moments.
3. **Mastery** — reward the long tail with permanent meta progress, not just bigger numbers.
4. **Pacing** — make every level-up a real decision, not a roll.

Skill Tree v1 (just merged) gave us tiers, evolutions, and six synergies. That was *plumbing*. Skill Tree v2 turns that plumbing into a **destination** — three named paths with personality, a fusion layer, and meta hooks that pull the player back tomorrow.

This doc is design-only. No code yet. The recommended build order is in §8.

---

## 1. The Three Paths

The fiction is already **sword × tech × magic** — a trio. The 13 archetypes split cleanly along it. v2 promotes that trio into the *primary* organizing layer.

| Path | Trope | Archetypes | Identity |
|---|---|---|---|
| **EDGE** | The blade — neon katana, monowire, chrome saber | chain, barrage, sentinel, focus, rupture | Strike-and-cut. Tempo, multi-hit, finishers. |
| **DAEMON** | The grid — drones, firewalls, orbital strikes | mothership, firewall, meteor, bounty | Systems and infrastructure. Lanes, network, economy. |
| **HEX** | The arcana — sigils, sutras, summoned spirits | nova, frost, snake, summon | Elemental ward and spirit. Zones, control, presence. |

This mirrors the names already in [skill_catalog.dart](../../lib/game/state/skill_catalog.dart): *Neon Katana Chain, Plasma Wakizashi, Overclocked Iaido* (Edge); *Tactical Mothership, Rune Firewall, Orbital Spellblade, Soulcoin Brand* (Daemon); *Mana Reactor Nova, Cryo Hex Ash, Fire Snake Ignite, Fire Wolf Spirit* (Hex).

### Why three, not four

The trio is already in the player's head from the cosmetic naming. A four-school redesign breaks that intuition. Three paths also gives only three pair combinations (§3 fusions), which keeps the named-hybrid set small enough to handcraft.

### Path color and visual signature

Each path inherits a single dominant color and VFX signature. This carries forward into the picker, in-world effects, and the Nexus core itself:

- **EDGE** = chrome white-cyan · afterimage slashes · sparkflash
- **DAEMON** = magenta-violet · glitch lattice · drone-trail
- **HEX** = gold-violet · runic glow · ofuda paper streamers

When a player's build leans into one path, the **Nexus core recolors** to match. Cheapest possible "my build looks cool" hook; pays for the entire categorization layer.

---

## 2. Path Tiers (set bonuses)

Total **archetype levels** inside a path unlock tiered passive bonuses. These are global; they don't cost a pick, they're earned by your distribution.

### EDGE — The Way of the Blade

| Tier | Levels | Effect |
|---|---|---|
| **Initiate** | 3 | Killed enemies leave a fading chrome afterimage (visual only). |
| **Adept** | 7 | Every 5th hit performs a phantom slash — single hit on the nearest two enemies. |
| **Master** | 12 | A permanent **Spectral Katana** orbits the Nexus and cuts on contact. |
| **Sword-saint** | 18 | **Iaido Draw** — every 30s, time freezes for a single frame; all on-screen enemies suffer one massive cut. |

### DAEMON — The Grid Below

| Tier | Levels | Effect |
|---|---|---|
| **Initiate** | 3 | A single passive companion drone trails the Nexus. |
| **Operator** | 7 | All drone, meteor, and firewall effects gain +20% range. |
| **Sysop** | 12 | A **Satellite Uplink** fires every 3s at the deepest enemy on screen. |
| **Root** | 18 | **Network Crash** — once per floor, every enemy suffers system-failure damage. |

### HEX — The Sigil Path

| Tier | Levels | Effect |
|---|---|---|
| **Initiate** | 3 | Every kill drops a tiny rune-spark (cosmetic + small mana refund). |
| **Adept** | 7 | Kills leave a lingering glyph that re-procs your most recent Hex effect. |
| **Mage** | 12 | A permanent **Ward Circle** surrounds the Nexus — enemies inside are slowed and burned. |
| **Ascendant** | 18 | **Awakened Sigil** — channeling a cataclysm spell paints the floor in your dominant element. |

### Why this works for an idle game

- Numbers go up *visibly* as you stack a path — every level-up has a downstream effect, not just a stat bump.
- Two ways to play: **wide** (touch all three paths, take Initiate everywhere) vs **deep** (one path to Sword-saint/Root/Ascendant). Both are valid; both feel different.
- Players naturally start asking "what does the next tier do?" — that's the curiosity loop idle games run on.

### Design rule

Tier effects must be **mechanically distinct from their archetype skills**. *Edge Master being "+30% blade damage" is boring stat creep.* *Edge Master being "a permanent Spectral Katana orbits the Nexus" is a new mechanic the player didn't have a minute ago.* Aim for new verbs, not bigger numbers.

---

## 3. Fusion Forms — named cross-path skills

Once a run has at least one archetype evolved (level 5 + evolution chosen) in **two different paths**, the picker may offer a **Fusion Form** — a unique cross-path skill that doesn't exist in the normal catalog. Rare, named, build-defining.

Three pair flavors, three Fusions each:

### EDGE × DAEMON — *Cyber-Saber* (chrome lit by network glow)

| Fusion | Effect |
|---|---|
| **Monowire Cascade** | Chain hops shred drone armor — chains gain +1 jump per active mothership drone. |
| **Chrome Iaido** | Barrage attack rate scales with current drone count. |
| **Killcode Edge** | Rupture executes inscribe binary on the next blade strike — that strike crits guaranteed and refunds 1 mana. |

### EDGE × HEX — *Runeblade* (sword wreathed in sigil)

| Fusion | Effect |
|---|---|
| **Glyphblade Cant** | Each chain hop inscribes a sigil node; closing the loop triggers a small nova. |
| **Phantom Frost** | Sentinel blades carry a frost charge — first hit chills, second shatters. |
| **Hexcut Mantra** | Every 3rd barrage hit applies a Snake-burn DOT for 3s. |

### DAEMON × HEX — *Magitech* (sigil-marked drones, runic lattice)

| Fusion | Effect |
|---|---|
| **Sigil Reactor** | Firewall lanes double Nova radius for any pulse cast inside them. |
| **Hexnet Drones** | Mothership drones inherit your active Summon spirit's aura. |
| **Bountysoul Ledger** | Frost kills inscribe gold sigils on the floor — stepping on one as Nexus doubles your gold for 3s. |

### How they appear

- Always offered as the **rarest** card in the pick screen, with a distinct gold/holographic frame and a **"FUSION"** banner.
- Only one Fusion per run unless a meta upgrade unlocks more — scarcity preserves them as memorable.
- Logged permanently the first time the player ever sees one (Codex unlock — see §6).

---

## 4. Sutras & Awakening — the long-tail meta hook

Idle games live or die on the answer to "what does my next run unlock?". Right now it's only embers and keystones. We need a deeper hook with vibe-correct naming.

### Sutras (per-archetype mastery)

When you finish a run with an archetype **evolved**, you earn **1 Sutra mark** in that archetype. Sutras are permanent and stack across runs. The fiction: each successful evolution inscribes the technique into the Nexus' memory-core.

Each Sutra mark gives, on subsequent runs:

- +1% to that archetype's primary stat (cap: 25 marks = +25%)
- A small visual flourish on the skill's projectile/effect (afterimage, glow, particle)
- At 5 / 10 / 25 marks, unlock **Sutra perks** (passive choices in the Meta screen — e.g., *"Chain Sutra X: chains can never miss"*; *"Mothership Sutra X: drones respawn 50% faster"*).

A determined player chases 13 archetypes × 25 marks = 325 Sutra. Months of long tail from a tag and a counter.

### Awakening (per-path prestige)

Once you have **all archetypes in a path at Sutra 25**, you may **Awaken the path**. Awakening resets that path's Sutras to 0 but grants:

- A permanent **path-glyph** branded on your profile.
- A new **Awakened skill** added to the catalog — e.g., *Edge Awakening: at run start, all Edge archetypes begin at level 1; the Nexus carries a permanent katana model.*
- Cosmetic: the Nexus core gains a path-colored ring per Awakening (max three rings = full Trinity Awakening).

Awakening is the *hardcore* hook: visible in screenshots, mechanically meaningful, narratively final.

---

## 5. The Sigil Matrix — visualization

The current picker is three cards on a dim overlay. Fine for v1. v2 deserves a richer surface because the system finally has structure to show.

Replace (or augment) the level-up dialog with the **Sigil Matrix** — a triadic constellation, one cluster per path:

- 13 nodes arranged in three colored constellations.
- Currently-owned skills glow at their level color.
- Locked archetypes (specialist/capstone tiers) appear as dim sigils with their unlock condition.
- Active synergy lines pulse between owned archetypes.
- Path tiers appear as a colored ring around each cluster, brightening as you fill it.
- Fusion Forms appear as floating starpoints **between** clusters once their cross-path conditions are met.
- The Nexus icon sits at the center, its color shifting as your build commits.

When a level-up triggers, three nodes pulse — those are the offers. The matrix collapses to a corner widget during gameplay so you can glance at it.

### Why a matrix, not a tree

A *tree* implies linearity (A unlocks B unlocks C). The skill system isn't linear — it's combinatorial. A matrix shows **all the choices and how they relate**, which is exactly what an idle player wants to plan around between runs.

### The "near orbit" rule for offers

Already partly implemented (tier gating). Extend it: among the available pool, weight slightly toward archetypes the player is **one step from synergy** (i.e., owns the partner already but not this one). The picker feels *responsive* — "the system knows what I'm building."

---

## 6. The Codex — discovery and completionism

A persistent meta screen listing every synergy, path tier, Fusion, and evolution the player has ever triggered. Frame it in-fiction as the **Nexus Memory-Core**.

- **Greyed-out** entries the player hasn't seen yet — they're a tease, not a spoiler. *("???"* for unfound Fusions.)
- **Filling the Codex pays embers.** Every first-time discovery awards a small bonus.
- **Codex 100% = Trinity Sigil** — a profile badge worth chasing. Visible on leaderboards if those ever ship.

Why this matters: it converts *random discovery* (which can feel like luck) into *predictable progress* (which feels like skill). And it gives a clear answer to "what's left to see in this game?" — currently, nothing.

---

## 7. Heretic Cants — run modifiers

Every 5 floors, instead of a level-up offer, give the player a **Heretic Cant** choice — three non-skill options that modify the rest of the run. The fiction: forbidden lines from the deeper system files.

- *Bloodprice:* +50% enemy damage, +50% gold drop.
- *Devotion:* future picks restricted to one path, but tier-up faster.
- *Diaspora:* future picks must rotate paths; weight bonus to unowned archetypes.
- *Greedglyph:* skip this floor's reward, double the next two.
- *Heretic's Bargain:* lose 20% Nexus HP now; gain a Fusion offer at next level-up.

These are **not skills**. They're flavor injections that break up the level-up cadence and create stories. Idle games need stories — *"the run where I went all-in on Edge and almost died on floor 18, then a Killcode crit saved me."*

Cants should be **optional** — let the player skip if they want. Forcing rhythm breaks irritates players in flow.

---

## 8. Build order

Implement in this order. Each stage ships on its own and improves the game even if the next stage never lands.

1. **Paths as a tag.** Add `path` field to `SkillArchetype` (Edge/Daemon/Hex). Display in picker tags, color the synergy lines, recolor the Nexus core based on dominant path. *~Half a day. Pure value.*
2. **Path Tiers.** Implement Initiate/Adept/Master/Sword-saint·Root·Ascendant checks in `game_state.dart`, apply effects in components. *~2 days. Big perceived-depth boost.*
3. **Fusion Forms.** Add `fusionCatalog` parallel to `evolutionCatalog`. Insert as rare offer in `_rollUpgradeChoices` when conditions met. *~3 days. The "wow" moment per run.*
4. **Codex.** Track first-time discoveries in `meta_state.dart`, display on meta screen. Award embers per first-time. *~2 days. Long-tail retention.*
5. **Sutras.** Per-archetype counter in meta state, applied at run start. *~2 days. The long-term commitment hook.*
6. **Awakening.** Per-path prestige; lock-icon final form. *~2 days. For the dedicated 1%.*
7. **Sigil Matrix UI.** Replace picker dialog. *~1 week. Polish stage; defer until systems are stable.*
8. **Heretic Cants.** Run-modifier system. *~3 days. Latest because it touches floor pacing — risk highest.*

Don't try to ship it all at once. Paths alone (step 1) is worth shipping by itself.

---

## 9. Player-incentive checklist

A skill of this depth still fails if the player doesn't *feel* the depth. Audit each new system against these five hooks:

| Hook | What the player feels | Where in v2 it lives |
|---|---|---|
| Numbers go up | "I can see my run getting stronger." | Path tiers; Sutra stacks |
| Surprise / discovery | "Wait — that combo did *what*?" | Fusion Forms; Codex blanks |
| Visible identity | "This is *my* Edge build." | Nexus recoloring; Sigil Matrix |
| Meta progress | "I unlocked X for next run." | Sutras; Awakening; Codex embers |
| Mastery achievement | "I did the thing only 1% of players do." | Trinity Awakening; Codex 100% |

Every system in this doc maps to at least one hook. If a future addition doesn't, it's probably noise.

---

## 10. Naming glossary (for code consistency)

To keep the fiction tight, prefer these terms when adding identifiers:

| Concept | Code term | Player-facing term |
|---|---|---|
| Path | `path` | EDGE / DAEMON / HEX |
| Path tier | `pathTier` | Initiate / Adept / Master / *(path-specific apex)* |
| Cross-path hybrid | `fusion` | Fusion Form |
| Per-archetype mastery | `sutra` | Sutra mark |
| Per-path prestige | `awakening` | Awakening |
| Discovery log | `codex` | Memory-Core / Codex |
| Run modifier | `cant` / `heretic` | Heretic Cant |
| Constellation UI | `sigilMatrix` | Sigil Matrix |

Avoid generic fantasy words (*element, school, perk, talent, mastery point, prestige token*). They erode the cyberpunk-katana-magitech voice.

---

## 11. What v2 deliberately does **not** add

To keep scope honest:

- **No new archetypes.** Thirteen is enough. Adding a 14th breaks the 5/4/4 path balance.
- **No randomized rare cards beyond Fusions.** Avoid loot-box feel. Discovery should be deterministic-once-conditions-met.
- **No PvP, no synchronous multiplayer.** This is a single-player descent; community comes from leaderboards and Codex pride.
- **No paid currency.** If monetization happens later, it should be cosmetic-only (skill skins, Nexus colors, Awakening rings). Mechanical depth stays free.

---

## 12. Open questions for playtesting

Decisions that should be made by feel, not by spec:

1. **How rare should Fusion offers be?** Once per run feels right; verify. Too rare and players never see them; too common and they lose mystique.
2. **Sutra cap** — is 25 per archetype enough? Could be 50 if early balance feels too fast.
3. **Path tier scaling** — does Master tier (12 levels) come too easily once a player commits? May need 14 or 15.
4. **Sigil Matrix as the *only* picker, or as a supplementary view?** Some players hate big UIs; offer both modes.
5. **Heretic Cants** — every 5 floors or every 10? 5 risks rhythm fatigue, 10 might feel forgotten.
6. **EDGE has 5 archetypes, DAEMON/HEX have 4.** Do path tier thresholds need adjusting per path to compensate, or does Edge naturally feeling slightly stronger fit the sword-fantasy?

---

*End of v2 design — Three Paths, one Nexus.*
