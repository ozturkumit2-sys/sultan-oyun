# PERFUME EMPIRE — Project State

Godot 4.5 (GDScript, gl_compatibility) · Android portrait 720×1280 (expand) · English UI · fully offline.
Package `com.perfumeempire.game` · save format version 3.

## Status (v1.0.0)

Playable end-to-end: new company → formulate → test → launch → produce → sell in 8 markets → grow the HQ,
staff, brands and offices → finance, investors, IPO, acquisitions. Every screen in the list below is
implemented and passes the automated smoke test. Not yet tested on a physical device.

### Verified automatically (headless)
| Check | Tool | Last result |
|---|---|---|
| All scripts parse | `_dev/t_parse.gd` | 0 failures |
| Every screen builds with a live mid-game world | `_dev/t_screens.gd` | all screens OK, no script errors |
| 10-year auto-play, accounting & integrity invariants every week | `_dev/t_validate.gd 10 11` | 0 issues; save/reload OK; post-load balance gap 0.00 |
| Screenshot tour (real renderer under Xvfb) | `_dev/t_shots.gd tour 70` | reviewed by eye |

Integrity invariants checked every simulated week for every company: assets − debt = paid-in + retained
(inventory, WIP and in-transit materials valued from physical records), no NaN/Inf, no negative stock,
formulas sum to 100 %, acquired companies hold nothing, no employee works for an inactive company,
no candidate is employed.

Performance (desktop, 10-year world with 8 rivals): ~250 ms per simulated week; save ≈ 4 MB after 10 years.

### Balance snapshot (seed 11, naive auto-player)
Year 1 revenue ≈ $0.5 M, year 3 ≈ $19 M, year 10 ≈ $33 M (auto-player caps itself at 12 products and 2 staff).
Rivals at year 10: $81 M – $750 M revenue. A good human player should be able to reach mid-table.

## Architecture

```
scripts/autoload/   DB (JSON data) · G (world state, RNG, helpers) · Save · Snd · Monet · Router (navigation, modals)
scripts/engine/     pure simulation, no UI:
  formula_engine    time-based performance model (evaporation curves, longevity, projection, sillage, accords,
                    interactions, clashes, stability, IFRA-like safety), labels and families
  consumer_engine   10 segments, perception, satisfaction, surveys (same engine as the market)
  market_engine     weekly deterministic market: cohorts country × segment × gender label, consideration =
                    awareness × reach, logit with outside option, loyalty, cannibalization, stockouts, returns,
                    reviews, word of mouth
  production_engine materials, reservations, contract manufacturers, own factory, batches, QC, rework,
                    rejection, maturation, recalls
  company_engine    products, brands, offices, HQ, distribution agreements, reach
  marketing_engine  campaigns (9 types), influencers & celebrities (fictional), brand budgets, attribution
  staff, perfumer_ai, lab, delegation, ingredient_market, finance_engine, corporate (investors, board, IPO,
  dividends, M&A, brand sales), rivals (8 AI houses), events, awards, review_engine, tutorial, world_gen
  sim.gd            the ONLY weekly processor; fixed order (see file header)
scripts/ui/         main.gd (bars, safe area, Android back) · screen.gd · ui.gd (widgets/theme) · comp/ (custom
                    drawn widgets: bottle, radar, charts, world map, HQ, avatars…) · screens/ (43 screens)
data/               ingredients (68), markets (8 countries, 10 segments), business (formats, packaging,
                    channels, campaigns, HQ tiers, roles…), competitors, names, texts, balance, world_map
assets/             fonts (OFL), audio (synthesized by _dev/gen_audio.py), icons (_dev/gen_icons.py), map
_dev/               test runner and tools — excluded from export
```

World state is one JSON-serializable Dictionary (`G.s`); engines are static classes. Saves are atomic
(write .tmp → rename, keep .bak, small .meta sidecar for the slot list).

## Screens
Main menu, new company, dashboard, lab hub, formulas, formula editor, ingredients, ingredient market, tests,
consumer research, proposals, briefs, products hub, product detail, launch wizard, production, reviews
(ScentNotes), awards, company hub, HQ, staff, employee, recruitment, perfumer transfers, world map,
distribution, brands, brand detail, marketing, new campaign, competitors, competitor, acquisitions,
delegation, finance hub, statements, loans, investors & board, weekly reports, inbox, settings, save/load,
discovery sets.

## Monetization
`scripts/autoload/monet.gd` is an architecture boundary only. It uses AdMob / Play Billing plugins if they
are present in the export; none are configured, so no ads or purchases exist and nothing is faked.

## How to run the tools
```
godot --headless --import                                   # after adding class_name scripts
godot --headless res://_dev/run.tscn -- parse                # parse all scripts
godot --headless res://_dev/run.tscn -- screens              # build every screen
godot --headless res://_dev/run.tscn -- validate 10 11       # years, seed
xvfb-run -a godot --rendering-driver opengl3 --resolution 720x1280 res://_dev/run.tscn -- shots tour 70
python3 _dev/gen_audio.py ; python3 _dev/gen_icons.py
godot --headless --export-release Android build/PerfumeEmpire.apk
```

## Known limitations / next steps
- Not yet played on a real Android device; performance on low-end phones unknown (week processing is
  the heaviest step, ~0.25 s on desktop).
- Balance is tuned against an automated player; human playtesting may show the mid-game is too easy or
  too slow.
- Review texts are template-based; some mixed reviews read slightly generic.
- Monetization plugins not configured (by design).
- Rival M&A between AI houses starts after year 5.
