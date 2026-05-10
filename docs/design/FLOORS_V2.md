# Floors v2 — Past the Architect

*Next-step pass for **Zenith Zero: Idle Descent**.*
*Picks up where Floors v1.5 ends.*

---

## 0. Why this exists

Floors v1.5 closed the *texture* gaps inside the F1→F25 arc. The framework now teaches itself: bosses telegraph, new enemies surface counter tips, the Codex tracks discoveries, the modifier catalog is fully wired, and F10/F20 hand out reward-room boons.

What v1.5 deliberately did not address:

- **F25 is a wall, not a horizon.** The Architect respawns on F30, F35, F40 with the same fight and a flat ember reward. There's no reason to keep going except a bigger number.
- **The reward room is a one-shot.** Two rooms across a 25-floor descent. The pool collapsed from 8 boons to 5 after we dropped the un-buildable ones in v1.5.
- **Discovery is gated to the death screen.** A new Bestiary entry pays embers and hides until the player dies. The discovery loop runs once per run.
- **Run end is anonymous.** The Nexus Breached panel shows floor, kill count, gold, embers — and nothing about *what the run was*. No memorable beats. No "I cleared three Hivebreaks" recap.
- **Every run is the same shuffle.** Modifiers and Crucibles roll independently each floor. There's no "today's challenge," no shared experience to compare against, no reason to play a *specific* run.

v2 is five items that turn the v1.5 framework into a **replayable** one. Total scope: ~2.5 weeks. The first three close gaps the v1.5 spec named in its own open-questions section. The last two introduce the smallest amount of new design needed to give the descent a horizon past F25.

This doc is design-only. Build order in §6.

---

## 1. Endless mode — Architect Echoes (F26+)

> **Figure 1: Endless ladder** — F25 is the trophy clear; F26+ is the Echo arc, with the Architect respawning every 5 floors, each time wearing a borrowed mechanic from one of the four earlier bosses.

Today, [`_grantBossReward`](../../lib/game/state/game_state.dart) at floor ≥ 30 falls into the `default` branch — a flat `50 + floor*5` ember payout and the same Architect fight. There's no ramp, no surprise, no reason F35 plays differently from F30.

### Proposal — Architect Echoes

Starting on F30, the Architect carries one **Echo modifier** drawn from the four earlier bosses' mechanics:

| Echo of | Borrows | Telegraph hint |
|---|---|---|
| The Watcher     | Spawns 3 Daemon-shielded adds at 75/50/25% HP | *"Echo of the Watcher. The shielded adds return."* |
| Glass Sovereign | Becomes splash-immune above 50% HP        | *"Echo of the Sovereign. Splash glances off."* |
| Hivefather      | Periodically heals from any nearby adds   | *"Echo of the Hivefather. Sustain through the brood."* |
| Cipher Twin     | Carries a permanent rotating immunity (3s window) | *"Echo of the Twin. Immunity rotates."* |

The echo cycles through the four in a fixed order — F30 Watcher, F35 Sovereign, F40 Hivefather, F45 Twin — then F50 returns to Watcher with a `+1` echo stack (a second mechanic layered on). The arc tops out at four stacks (F90), at which point the Architect carries all four mechanics simultaneously.

### Endless rewards

- **Echo clears** pay `100 + (floor × 10)` embers — modest but compounding.
- Each new echo *first-clear* adds an entry to the Codex (`echo:watcher`, etc.) and pays a one-time +25 ember bounty, same shape as Bestiary discoveries.
- The F25 permanent unlock queue from v1.5 stays sealed (5 entries, claimed once each). Endless does *not* award unlocks — it's pure leaderboard-style depth.

### Why this matters

The longest-tail player today has nothing to chase past F25 except more embers, which the meta-shop can already drown in. Endless turns the post-F25 tail into a *content* arc — different fight, different counter, different Codex row to fill.

---

## 2. Reward rooms every five floors past F10

The v1.5 doc explicitly flagged this as open question #2: *"F10/F20 only, or every boss after F10?"* Two rooms gave players a taste; five would let the system breathe.

### Proposal

Trigger the post-boss reward room after **every** boss starting at F10 — F10, F15, F20, F25, and every 5 floors in Endless. F5 stays clean (the Watcher reward is already a payout beat; piling a boon room on top would dilute the F10 milestone).

### Boon pool expansion (5 → 8)

The pool shrank to 5 working boons after v1.5 dropped `revealModifier`, `halveCantCost`, and `skipNextCant` were trimmed/wired. Add three new boons designed to actually fit existing systems:

| Boon | Effect | Hooks into |
|---|---|---|
| **Inflection Spark** | Next level-up offers an Inflection on a skill of your choice. | `_rollUpgradeChoices` — set `_pendingInflectionSkillChoice = true`. |
| **Path Resonance** | +1 stack toward your dominant path's tier (one-time, this run). | `dominantPath` already computed; nudge `pathScores` directly. |
| **Modifier Preview Lens** | The next floor's modifier is shown in the HUD chip strip *before* you commit to advancing. | New: pre-roll `_advanceFloor`'s modifier set into a `previewModifiers` field; HUD reads it during the inter-floor beat. |

The lens is the v1.5 *Prescience Core* boon, but this time with the inter-floor preview UI it needs to mean something. Build it once; reuse it in §3 below.

### Pacing risk

Five rooms in a 25-floor descent is one every five floors — same cadence as the modifier rolls. Playtest for fatigue; if it pulls the player out too often, drop F15 and keep F10/F20/F25.

---

## 3. In-run Codex slate

> **Figure 3: In-run codex slate** — a corner button on the HUD opens a translucent panel listing recently discovered Bestiary and Crucible entries, plus the current run's modifier history.

Right now the Codex (with v1.5's Bestiary and Crucibles tabs) is reachable only through the Nexus Breached death panel. A new player who just discovered the Aegis can't go look at what they discovered until they die.

### Proposal

Add a **codex slate** opened by a small icon in the HUD's top-left, next to the floor chip. Opening it pauses the run (same overlay treatment as the level-up picker) and shows three sections:

1. **This run** — modifiers seen, Crucibles survived, bosses cleared. Resets each run.
2. **Recent discoveries** — last 5 Codex entries unlocked (any tab), with the +5 ember toast inline.
3. **Bestiary peek** — same grid as the death-screen Bestiary, read-only, scrollable.

The Boons / Keystones / Meta-shop tabs are **not** in the slate — those are deliberately gated to the death screen. The slate is *reference* during a run, not *progression*.

### Why pause-not-overlay

If the slate doesn't pause, the player takes damage while reading and the slate becomes a punishment. Pause matches every existing modal in the game (level-up, fusion, cant, sutra picker, reward room).

### Implementation

The data is all already in `MetaState` and `GameState`. The new surface is one widget in `lib/ui/hud.dart`. Reuse `_BestiaryList` and `_CrucibleList` from `meta_screen.dart` directly — they already accept a `MetaState` and render read-only.

---

## 4. Run summary recap

The Nexus Breached screen today says *"Floor 14 · 287 kills · 412 gold."* That's the same recap whether the player got chewed up by a Splinter cascade on F8 or held until the Hivefather mid-fight on F15. The run had a shape; the recap shows none of it.

### Proposal

Replace the header line with a five-row recap card on the death screen:

```
RUN 47                                    F14 · 287 kills

PEAK FLOOR        F14 (Hivefather)
LONGEST PHASE     F12 Crucible · 41s
BEST KILL STREAK  18 in 6.2s
WORST DAMAGE      Splinter cascade · F11 · 28% HP
EMBERS EARNED     412
```

All fields are already trackable from existing GameState fields:

- `peakFloor` — already known (`floor` at death).
- `longestPhase` — track `(phase, floor, duration)` as a high-water mark in `_updatePhase`.
- `bestKillStreak` — `_lastKillAt` already tracks streak; capture max each run.
- `worstDamage` — record largest single `damageNexus(amount)` call this run with its source enemy type and floor.
- `embersEarned` — already in `meta.lastEmbersEarned`.

### Why five rows, not twenty

Five is the number of beats a player can actually remember. Twenty is a stat dump. Each row is a *story beat* — a thing the player can later say out loud about the run. ("I almost survived the Hivefather, but a Splinter cascade did me in on 11.")

---

## 5. Daily Descent — one seed, one day

Every run today is independent: random modifiers, random Crucibles, random Architect echoes. There's no shared experience between two players, no "did you see what F12 rolled today," no reason to play a *specific* run.

### Proposal — Daily Descent button

A second button on the title screen (next to *Begin Descent*): **Daily Descent**. Tapping it starts a run with:

- A seed derived from `YYYY-MM-DD` (UTC).
- The same modifier rolls, Crucible rolls, and boon offers for every player on that date.
- A separate "Daily Best" stat tracked in `meta_state` per date — peak floor + embers.
- One attempt per day; resetting requires waiting until UTC midnight.

### Why daily, not weekly or arbitrary seeds

- *Daily* is the cadence every other game with this feature uses (Spelunky, Slay the Spire, Balatro). Players already know the contract.
- A new seed every day is a forcing function to come back tomorrow.
- One attempt per day creates pressure — *this run matters* — without needing leaderboards or accounts.

### What stays out of scope

- **No leaderboards.** Single-player descent (per v1's contract). Daily Best is local.
- **No daily challenge modifiers.** The seed *is* the challenge — same modifiers everyone else got.
- **No streak rewards.** A streak system implies retention loops we haven't designed yet. v2.5 territory.

### Implementation

`math.Random(seed)` already exists in `GameState` — replace the `_rng` constructor with a daily-derived seed when the run is daily. Add a `bool isDaily` flag to GameState. Add one row to MetaState:

```dart
Map<String, ({int floor, int embers})> _dailyBests = {};
```

That's it. The whole feature is a button, a seeded RNG, and one persistence field.

---

## 6. Build order

Strict priority. If you only have a week, ship #1 and #4.

1. **Architect Echoes (Endless)** *(4 days)* — biggest player-retention payoff per dev-day; fixes the "F25 is a wall" complaint.
2. **Run summary recap** *(2 days)* — small surface, high "memorability" return. Most of the data already exists.
3. **Reward rooms every 5 floors + 3 new boons** *(3 days)* — answers v1.5 open Q2; the Modifier Preview Lens unlocks #3's UI.
4. **In-run Codex slate** *(2 days)* — closes the v1.5 discovery loop the death-screen gating left half-open.
5. **Daily Descent** *(2-3 days)* — last because it's net-new feature surface; the previous four polish what already exists.

Total: ~13-14 working days. Two ~one-week increments, same cadence as v1.5.

---

## 7. Player-incentive checklist

Same five hooks. v2 reinforces:

| Hook | v2 addition |
|---|---|
| Numbers go up | Endless ember scaling; daily best PR; expanded boon pool |
| Surprise / discovery | Architect echoes rotate mechanics; new boon types; codex slate exposes recent unlocks |
| Visible identity | Run summary names the run's beats; daily seed gives every run a *name* (the date) |
| Meta progress | Reward rooms more often → more permanent-feeling boons per descent |
| Mastery achievement | Echo Codex tier; F90 four-stack Architect as the new ceiling; daily streak (visible, not rewarded) |

---

## 8. What v2 deliberately avoids

- **No new bosses, enemies, or modifiers.** Same v1 catalog. v2 expands the *frame*, not the content.
- **No leaderboards or accounts.** Daily Descent is local.
- **No active player abilities.** Auto-RPG holds.
- **No mid-run save/restart.** Death is final, including for daily attempts. (One attempt per day is the contract.)
- **No new permanent-unlock entries.** The v1.5 unlock queue has 5; that's the trophy set. Endless intentionally does not gate behind unlocks.
- **No streak rewards or login bonuses.** v2.5 territory if it ships at all.

---

## 9. Open questions for playtesting

1. **Echo cadence** — every 5 floors (F30/F35/F40/F45) or every 10 (F30/F40/F50)? Five is the v1 cadence; ten lets each echo breathe longer. Playtest both.
2. **Stack limit** — four stacks (F90 ceiling) suggested. Drop to three if F90 is unreachable in practice; raise to five if streamers complain about the wall.
3. **Daily Descent retries** — one attempt is dramatic but punishing. Allow a single retry if the run ends before F5? Verify with non-hardcore players.
4. **Reward room cadence** — every 5 floors might be too frequent. If pacing fatigues, drop F15.
5. **Codex slate keybind** — tap-only, or also a keyboard shortcut on desktop? Mobile is the primary target; desktop may not justify the binding.
6. **Run summary social share** — eventually, *PEAK FLOOR* is the kind of stat players screenshot. Does the recap card need to render cleanly when screenshot? Probably yes, but not a blocker for v2.

---

*End of v2 — five items, two-and-a-half weeks, one descent that no longer ends at F25.*
