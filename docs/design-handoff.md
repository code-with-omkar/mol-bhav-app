# MolBhav design hand-off

The current look is a working placeholder. This lists what a redesign must cover and where the styling lives.
Last updated 1 Nov 2026.

## Where styling lives (change these first)

- `app/lib/core/theme/mb_colors.dart` — every colour token, light and dark.
- `app/lib/core/theme/mb_typography.dart` — every text style (Hindi / Devanagari variants included).
- `app/lib/core/theme/mb_dimens.dart` — spacing scale (`MbSpacing`) and corner radii (`MbRadius`).
- `app/lib/core/theme/app_theme.dart` — builds the light and dark Material themes from the tokens.
- `app/lib/shared/widgets/` — the reusable pieces (buttons, cards, text fields, app bar, bottom nav, charts,
  list rows, loading / empty / error views, icons). Restyling these restyles most screens.

Screens read colours and text styles through `context.mbColors` and `context.mbText`, so a new palette or type scale
should not need screen-by-screen edits.

## Known places that bypass the theme (fix during the redesign)

- 3 uses of `Colors.*`: the debug server-address tile, the checkout page overlay, the weather card gradient.
- 10 `fontSize:` literals and 17 padding values not taken from `MbSpacing`.
- Everything else uses tokens (no hex colours outside the theme files).

## Things the design must handle

- Light and dark mode (both exist today).
- Languages: English, Hindi, Marathi are fully translated; other languages fall back to English. Devanagari text is
  longer and needs taller line height; test buttons and chips with it.
- Every data screen has four states: loading, empty, error (with retry), and content. See `mb_state_views.dart`.
- Offline: the app shows "No internet connection" style errors rather than blank screens.
- The Server address setting (login screen) is debug-only and not part of the product design.

## Screens to cover

### User app (signed-in)

- Tabs (bottom navigation): Home, Markets, Watchlist, Alerts, More.
- Home: hero header, quick actions (cost estimate, reports, compare markets, add to watchlist), categories grid,
  top opportunities slider, watchlist preview, weather card (+ weather detail page and location-permission gate),
  sponsored ad slot.
- Markets: market comparison, price trends (chart), prices by mandi, buying opportunity detail.
- Watchlist: list and add.
- Alerts: opportunities list, alert rules, create alert.
- More: profile and categories, subscription, language, notification settings, personalised ads, weather animation,
  invite a friend, help and support (raise ticket, my tickets, ticket thread), log out.
- Tools: cost estimator, reports.
- Billing: plans, checkout, success, my subscription.
- Notifications: preferences screen.

### Before sign-in

- Boot splash (animated logo), login (phone / password / Google, language picker), OTP verification, business profile,
  category selection.

### Messages that cover or sit on top of the app (NEW in Oct 2026)

- "Prices may be delayed" banner (amber strip, dismissible).
- App message banner (note = green strip, warning = amber strip, dismissible).
- Maintenance page ("We will be back soon", message, Check again) — full screen, cannot be dismissed.
- Update required page ("Please update MolBhav", version needed, Update now) — full screen, covers login too.
- Sponsored ad card and AdMob native ad slot; ad unlock sheet (rewarded ad).

### Admin app (NEW in Oct 2026; admins only, phone-first)

- Own bottom tabs: Dashboard, Ads, Users, App. A person icon in the top bar switches to the normal user view.
- Dashboard: headline stat cards (users, ads, price feeds, support).
- Ads: totals with change vs previous period, clicks-per-day chart, placement cards, campaign cards,
  campaign detail (three charts).
- Users: searchable list with badges, user detail with suspend / reinstate and a confirmation.
- App: price-feed health card plus entries for app message editor, minimum app version editor, feature switches,
  data pull schedules (with Run now filter sheet and dropdown pickers), pull history and run detail.

## Components that exist only in the admin app

- Stat card with change line (green up / red down), choice-chip range selector (7 / 30 / 90 days),
  multi-select dropdown field, switch rows, form editors with preview.

## Not designed yet (no screen today)

- Language picker outside the login screen (More shows the language but cannot change it).
- Store listing assets: app icon, splash, screenshots (wait for the new design).
