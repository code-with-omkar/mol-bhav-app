# Retail App — Project Brief & Instructions for Claude Code

## Context
- Building a cross-platform mobile app (Android & iOS) for a local retail business.
- Starting category: retail products. Planned expansion: vegetables and other categories.
- Backend (.NET Core Web API) and database (SQL Server) are already built. API details will be shared separately when development starts.
- Note: current DB is SQL Server; may need to migrate/support a different DB (e.g. PostgreSQL) for free hosting options. Not needed for the design phase.

## Target audience
- Rural areas in Maharashtra.
- Budget Android phones, possibly unreliable internet.
- Prefer visual, simple navigation with large tap targets.
- May prefer calling/WhatsApp ordering alongside in-app cart.
- Likely payment: cash on delivery, UPI.
- Mobile number + OTP login preferred over email/password.

## Languages
- Marathi, Hindi, and English — business plans to expand beyond the current region.
- Marathi-first as default, with an easy switch.
- Use Flutter's `intl` + ARB files (`app_mr.arb`, `app_hi.arb`, `app_en.arb`) — no hardcoded strings in widgets.
- Product/category names need translation support in the DB too (translation table recommended: `ProductTranslation(ProductId, LanguageCode, Name, Description)`), not just UI strings.
- Design components for variable text length (Devanagari text runs longer than English).

## Brand direction
- Theme: soft, nature-oriented.
- Name: user is selecting from options like Ankur, Pallav, Aapla Bazaar (final name TBD — confirm before hardcoding anywhere).
- Palette (starting point):
  - Primary (leaf green): `#4F8A5B`
  - Primary dark (forest): `#2F5D3A`
  - Accent (marigold): `#E8A33D`
  - Background (soft cream): `#FAF7F0`
  - Surface (pale sage): `#EAF2E6`
  - Text (warm charcoal): `#2B2B2B`
  - Error (muted terracotta): `#C8553D`
  - Caution: soft palette risks low contrast in sunlight on budget screens — verify contrast ratios (4.5:1 min for body text).
- Typography: Noto Sans Devanagari or Mukta/Hind for body text, paired Latin font, larger base size (16-18sp).
- Shape language: rounded corners (12-16px), soft/no shadows, generous white space.
- Logo: works in one color, readable at app-icon size, leaf/sprout/village motifs under consideration.

## Tech stack
- Flutter (Android & iOS from one codebase).
- State management: Riverpod.
- Routing: go_router.
- HTTP: Dio, with JWT auth interceptor.
- Secure storage: flutter_secure_storage.
- Images: cached_network_image.
- Architecture: feature-first folder structure (see below).

## Project structure
```
lib/
  core/
    network/dio_client.dart
    storage/secure_storage.dart
    theme/app_theme.dart
    router/app_router.dart
    l10n/ (ARB files)
  features/
    auth/
    products/
      data/
      presentation/
    cart/
    checkout/
    orders/
    profile/
  main.dart
```

## Screen inventory (v1)
- Splash, Login/Register (mobile + OTP)
- Language picker (first launch)
- Home (categories, banners, featured)
- Category list / Product list (search, filter, sort)
- Product detail
- Cart
- Address / Checkout
- Order confirmation
- Orders list / Order detail
- Profile

## Design principles (must hold across all screens)
1. Marathi-first, easy language switch, full localization from day one.
2. Visual over textual — large product photos, icon + label for categories.
3. Large tap targets (48dp+), shallow navigation, minimal taps to checkout.
4. Low-bandwidth friendly — compressed images, skeleton loaders, catalog caching, offline states.
5. Local units (kg, gram, dozen, litre) and clear ₹ pricing.
6. Trust signals — delivery info, contact number, COD option.
7. Lightweight — avoid heavy animation/large assets for budget devices.

## Status / Next steps
- [ ] Finalize app name
- [ ] Finalize logo
- [ ] Build Flutter theme file from palette above
- [ ] Scaffold project structure
- [ ] Build first vertical slice (product list) against real API once shared
- [ ] Set up ARB files for 3 languages

## Instructions for Claude Code
- Follow the design principles and screen inventory above when scaffolding UI.
- Use the specified stack (Flutter + Riverpod + go_router + Dio) — do not substitute state management or routing libraries without asking.
- Do not hardcode any user-facing string; route everything through localization from the start.
- Do not assume the app name — treat it as a placeholder until the user confirms it.
- API integration details will be provided separately; scaffold with mock/sample data structured per the "Screen inventory" and reasonable assumed DTOs until real endpoints are shared.
- Ask before making architectural decisions not covered in this brief (e.g. offline sync strategy, push notification provider).
