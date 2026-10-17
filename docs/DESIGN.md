# SketchSquare design system — "Blueprint / Studio"

> **Status: tokens + shared kit are merged. Redesign the remaining screen groups on top of it** (see
> [Adoption status](#adoption-status)). Home, Search, the shared `DrawingCard` and the bottom bar already use it —
> copy their patterns.

The look: warm drafting-paper neutrals, a deep blueprint-blue primary, a copper accent used sparingly (the "red pencil"),
Space Grotesk display type (technical lettering) over Inter body text, blueprint-grid motifs and dimension-line glyphs
instead of stock icons. Premium, calm, precise — it should feel like a drafting studio, not a template.

Everything lives in `sketch_square/lib/core/`. Import the kit with one line:

```dart
import 'package:sketch_square/core/widgets/widgets.dart'; // kit + tokens + price formatter
```

## Rules of thumb

**Do**
- Take colours from `Theme.of(context).colorScheme` and `AppSemanticColors.of(context)`; spacing from `AppSpacing`,
  radii from `AppRadius`, durations from `AppMotion`. Never hard-code a colour, radius or `EdgeInsets` number that has a token.
- Use kit widgets before writing a new `Container`/`Card`/`ElevatedButton`. If the kit lacks something two screens need, add it
  to `core/widgets` (and here) instead of copy-pasting.
- Use `PriceText`/`formatPaise` for every price and `PlotSizeBadge`/`formatPlotSize` for every plot size (tabular figures).
- Every list/grid that loads shows a skeleton (`DrawingCardSkeleton`, `ListRowSkeleton`, `ShimmerBox`), never a lone spinner.
- Empty and error states are `EmptyState` / `ErrorState` (or the API-compatible `BlueprintEmptyState` / `ErrorRetry`).
- Keep hit targets ≥ 48 dp and labelled; test at text scale 1.3 and in dark mode (`test/a11y/` does this for every route).
- Wrap rows that can get long in `Flexible`/`Expanded`/`Wrap`; titles get `maxLines` + ellipsis.

**Don't**
- Don't colour-code meaning without text (`StatusPill` always carries a label).
- Don't use the copper accent for more than one element per screen (it marks the hero/primary-adjacent highlight).
- Don't nest cards inside cards; separate with spacing or `Divider`.
- Don't add infinite animations (the shimmer is capped at 8 loops on purpose) or animation that ignores
  `MediaQuery.disableAnimations`.
- Don't introduce new fonts, ad-hoc shadows (`AppElevation`) or full-screen spinners.

## Tokens (`core/theme/`)

| File | What |
| --- | --- |
| `app_colors.dart` | `AppColors` constants + `AppSemanticColors` theme extension |
| `app_tokens.dart` | `AppSpacing`, `AppRadius`, `AppElevation`, `AppMotion` |
| `app_typography.dart` | `AppTypography.textTheme`, `TextStyle.tabular` extension |
| `app_theme.dart` | `AppTheme.light()` / `AppTheme.dark()` — full Material 3 + component themes |
| `app_page_transitions.dart` | Fade + 4 % rise page transition (Android/desktop/web; Cupertino slide on iOS/macOS) |

### Colour

| Role | Light | Dark |
| --- | --- | --- |
| Primary (blueprint blue) | `#1F3A93` | `#9DB1F5` |
| Ink (hero surfaces, wordmark) | `#0B1E52` | same |
| Background (drafting paper) | `#F6F5F1` | `#0B0F17` |
| Surface / card | `#FFFFFF` | `#131925` |
| Text / muted text | `#0F1729` / `#555F73` | `#F0F2F7` / `#9EA8BB` |
| Outline / soft outline | `#DAD7CE` / `#E9E7E0` | `#2B3548` / `#1F2839` |
| Accent (copper) | `#B5541B` (tint `#FBE8DA`) | `#F2AA7B` |
| Success (emerald) | `#16714A` | `#74D4A4` |
| Warning (amber) | `#B7791F` | `#F3C969` |
| Error | `#B3261E` | `#F2B8B5` |

Use `colorScheme.primary/onPrimary/primaryContainer/surface*/outline*/error` for standard roles and
`AppSemanticColors.of(context)` (`success`, `warning`, `accent`, `ink`, `onInk`, their containers) for the rest.
Elevation is subtle: surfaces step through `surfaceContainerLowest → Highest`; shadows only via `AppElevation.level1/2(brightness)`.

### Spacing, radius, motion

- `AppSpacing`: `xxs 2 · xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · huge 48`, and `gutter 20` (screen horizontal padding).
- `AppRadius`: `xs 6 · sm 10 · md 14 (controls) · lg 20 (cards) · xl 28 (hero/sheets) · pill`. Helpers: `cardRadius`, `controlRadius`, `chipRadius`.
- `AppMotion`: `fast 120 ms · base 220 ms · slow 360 ms`, curves `curve` (easeOutCubic) and `emphasized`.

### Typography

Space Grotesk for `display*`, `headline*`, `titleLarge`; Inter for everything else. Loaded through `google_fonts`
(falls back to the platform font offline; tests set `AppTheme.useGoogleFonts = false`).

| Style | Size | Use |
| --- | --- | --- |
| displayLarge/Medium | 44 / 36 | marketing/intro only |
| headlineMedium/Small | 28 / 24 | hero headings |
| titleLarge | 19 | app-bar titles, `SectionHeader` |
| titleMedium / titleSmall | 16 / 14 | card titles, prices |
| bodyLarge / Medium / Small | 16 / 14 / 12.5 | body, secondary text |
| labelLarge / Medium / Small | 14 / 12 / 11 | buttons, chips, badges, nav labels |

Dimensions, plot sizes, prices and counters use tabular figures: `style.tabular` (already applied inside `PriceText`,
`PlotSizeBadge`, `StatTile`, `AppTextField(tabularFigures: true)`).

## Components (`core/widgets/`, all exported by `widgets.dart`)

| Widget | Purpose / key params |
| --- | --- |
| `AppCard` | Surface container. `style: elevated \| outlined \| tonal`, `onTap` (adds `TapScale` + ink), `padding`, `semanticLabel`. |
| `SectionHeader` | Title + optional `subtitle` and `actionLabel/onAction` ("See all"). Default padding already has the gutter. |
| `PrimaryButton` / `SecondaryButton` | `label`, `onPressed`, `icon`, `loading` (spinner, taps ignored), `expand` (default full width), `accent` (copper, Primary only). |
| `AppTextField` | Form field with consistent label/hint/helper/error, `prefixIcon`, `suffix(Text)`, `obscureText`, `validator`, `tabularFigures`. |
| `InkHeroCard` | Ink gradient + blueprint grid surface for hero blocks (wallet balance, order result). Put white text inside. |
| `SummaryRow` | Label / tabular value row for price summaries and receipts; `emphasis` makes it a total. |
| `StatTile` | Big tabular number + label + optional icon/`onTap` (wallet, profile, admin dashboards). |
| `StatusPill` | Small label chip. `tone: neutral \| info \| success \| warning \| danger \| accent`, optional `icon`, `dense`. |
| `AppAvatar` | Initials avatar with network image fallback (`name`, `url`, `size`). |
| `PlotSizeBadge` | `30×40 ft` with a proportional plot glyph. `onImage` = frosted dark variant for photos, `large` for detail headers. |
| `PriceText` / `RatingLabel` | `PriceText(paise:, compact:)` (₹9,999 / ₹1.2L); rating star + value or "New". |
| `Shimmer`, `ShimmerBox`, `DrawingCardSkeleton`, `ListRowSkeleton` | Skeleton loaders. Wrap custom skeletons in `Shimmer`. |
| `EmptyState` / `ErrorState` | Blueprint illustration + title/message/action. `variant: plan \| plot \| broken`, `tone`, `compact`. `ErrorState(message:, onRetry:)`. |
| `BlueprintIllustration`, `BlueprintGrid(Painter)` | CustomPaint motifs for custom heroes (no image assets). |
| `BrandMark`, `Wordmark` | Logo tile and "SketchSquare" lock-up (Home app bar). |
| `TapScale` | Press-in micro-interaction (0.98) for any tappable surface. |
| `DrawingThumbnail` | Small rounded preview with shimmer placeholder (rows, lists). |
| `DrawingCard` (`features/drawings`) | Image-first tile: hero-tagged preview, plot-size badge, size-match chip, title, city, price/FREE, rating. Same API: `drawing`, `onTap`, `favoriteAction`. |

Shared formatters: `core/format/price.dart` → `formatPaise(int)` (`₹1,24,999`) and `formatPaiseCompact(int)`.
`features/drawings/presentation/formatters.dart` re-exports `formatPaise` for existing imports.

### Patterns

- **Screen scaffold:** `Scaffold` + `AppBar` (themed: flat, left-aligned title) + body padded by `AppSpacing.gutter`. Sections are
  separated by `SectionHeader`s (top padding `AppSpacing.xl`).
- **Hero block:** ink gradient + `BlueprintGridPainter` + copper kicker label + white `PlotSizeFields`/form on a surface card
  (see Home `_PlotSizeHero`).
- **Lists/grids:** `pagedDrawingSlivers` already renders skeleton → cards → load-more → error/empty states.
- **Hero transition:** `drawingHeroTag(context, id)` tags the card preview and the detail gallery (`DrawingGallery(heroTag:)`); the tag
  is scoped per tab Navigator so the same drawing in two tabs never collides.
- **Motion:** pages fade + rise (220 ms); bottom-bar icon pops on select; cards/buttons scale on press; skeleton shimmer is finite.
- **Forms:** `AppTextField` for fields, `PrimaryButton(loading:)` for submit, errors inline (not only snackbars).
- **Sheets/dialogs/snackbars** are themed (28 dp top radius + drag handle, floating snackbars) — use the stock widgets.

## Responsive (phone · tablet · desktop/web)

The phone layout is the baseline and must not change. Wider windows get native-feeling layouts built from `core/layout/`
(`import 'package:sketch_square/core/layout/layout.dart'`, also re-exported by `widgets.dart`):

| Class | Width | Chrome |
| --- | --- | --- |
| `ScreenSize.compact` | < 600 | bottom `NavigationBar`, 2-column grids |
| `ScreenSize.medium` | 600 – 1024 | `NavigationRail`, 2–3 columns |
| `ScreenSize.expanded` | > 1024 | top navigation bar (web), 3–4 columns |

- `context.screenSize` / `context.isCompact` / `context.isWide` / `context.isExpanded` read the window width
  (`Breakpoints.of(width)` for sub-area widths from a `LayoutBuilder`).
- `ContentFrame(width: ContentWidth.browse | form | full)` centres content and caps it: **1200** for browse screens,
  **560** for forms/auth/checkout/wallet/settings. `AdaptiveScaffoldBody` is the same as a `Scaffold.body` wrapper.
  Backgrounds (Scaffold, hero gradients) stay full-bleed; only content is framed. The app shell already frames every tab
  screen, so screens normally need **no** per-screen code.
- `AdaptiveGridDelegate(mainAxisExtent: ...)` is the shared card-grid delegate (min tile 230 → 2/3/4 columns from the
  sliver's real width). `pagedDrawingSlivers` uses it; use it for any new card grid instead of horizontal strips.
- **Shell** (`features/shell/presentation/app_shell.dart`): compact keeps the bottom `NavigationBar`; medium shows a labelled
  `NavigationRail` (`nav-rail`); expanded shows a 64 px top bar (`top-nav`: brand, Home/Featured/Upload, search pill,
  basket, profile). Same `StatefulShellRoute` and route paths on every size.
- **Route widths**: the shell frames each route by path via `contentWidthForPath` (`core/router/route_content_width.dart`):
  browse 1200 (default), list 760 (`/basket`, `/profile`, `/manage-drawings`, `/admin*`), form 560 (upload, checkout,
  wallet, edit profile, settings, legal). Routes pushed outside the shell (admin, legal, manage drawings) wrap themselves
  in `ContentFrame`. New routes get browse width unless added to the mapping.
- **Plot-size hero**: `PlotSizeFields(trailing: ...)` puts length × breadth, the ft/m toggle and the action on one line
  when it is ≥ 600 wide; Home caps the card at 720 on wide windows. Elsewhere it keeps the stacked phone layout.
- **Filters**: `showFiltersSheet` opens a centred 560 dialog on wide windows (bottom sheet on phones). Every modal
  bottom sheet is capped at 640 wide by `bottomSheetTheme`; `AlertDialog` is already ≤ 560.
- **Drawing detail** (expanded only): two columns, gallery + sheets + reviews on the left; title, specs, purchase card
  (`PurchaseBar(inline: true)`), description and architect on the right. Below 1024 it keeps the single column with the
  sticky `PurchaseBar`. Home hides its own brand AppBar when the top nav shows the brand.
- **Web affordances**: `AppCard` lifts (stronger shadow + border) on hover and shows a 2px primary focus ring on keyboard
  focus; `AppScrollBehavior` lets a mouse/trackpad drag carousels and the gallery; theme `hoverColor`/`focusColor`
  are set; `FocusTraversalGroup` uses reading order; icon buttons carry tooltips; the detail description is
  `SelectableText` on wide windows. Desktop platforms get Flutter's automatic scrollbar.
- Tests: `pumpApp(size: ...)` sets the surface; with no surface set it defaults to 390×844 so existing tests see the
  compact layout.
- Don't hard-code widths for "desktop"; use the helpers above so tablets and resized windows behave too.

## Testing

`test/core/widget_kit_test.dart` renders the kit at 1.3× text in light and dark. `test/a11y/` visits every route in both themes at
1.3×. `inAppBar('Home')` in tests matches the `Wordmark` (the Home tab has no text title).
`pumpApp` sets `AppTheme.useGoogleFonts = false`; widget tests must do the same.

## Adoption status

| Screen group | Status |
| --- | --- |
| Theme, bottom navigation, page transitions | Done |
| Home (hero plot-size search, categories, feed; hero ≈ 225 dp) | Done |
| Search (sticky field + filter button, active chips + Clear all, result-count header + sort pill, plot-specific empty state with one-tap widen, filters sheet with plot size/tolerance preview, price range, chips, sort) | Done |
| Shared `DrawingCard`, skeleton grid, Featured/Favorites/Architect grids | Done (inherited) |
| Drawing detail (immersive collapsing gallery, title/price, spec `StatTile` grid, architect card, rating summary, sticky purchase bar, licence note) | Done |
| Architect profile (`AppAvatar` header, Rating/Drawings `StatTile`s, skeleton) and Featured tab (city picker, ranked top-architect cards with `#N` badge + rating + drawing count, skeleton row, tonal empty/error) | Done |
| Auth: sign-in, sign-up (2-step), forgot/reset, verification upload form | **Done** (`AuthHero`, `StepProgress`, `PasswordStrengthMeter`, `AppTextField`/`PrimaryButton`) |
| Auth: intro, splash, verification status (timeline), Privacy/Terms | **Done** (frosted intro controls, `BlueprintIllustration` + status timeline, tonal legal notice) |
| Upload flow (stepper, sectioned steps, thumbnail sheet tiles with progress rings, live `DrawingCard` preview, celebratory publish state) | Done |
| Basket + checkout + order result | Done |
| Purchases library + download/review sheet | Done |
| Profile tab, settings, edit contact details | Done (`SettingsGroup`/`SettingsTile` in `features/profile`) |
| Wallet (balance, ledger, bank, payouts, withdraw sheet) | Done (`InkHeroCard` balance, ledger grouped by day) |
| Manage drawings (`ManagedDrawingCard`: status pills, stats strip, summary tiles, skeleton + empty states, restyled edit sheet) | Done |
| Admin (verifications, refunds, plagiarism, categories) | **To do** |

When you finish a group, update this table in the same PR.
