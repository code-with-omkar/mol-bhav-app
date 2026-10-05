# Dark Theme Implementation — MolBhav Flutter App

## Model
- Claude (Opus/Sonnet)
- Context: Flutter app with BLoC state management, Riverpod for providers
- Focus: Complete dark theme implementation across entire app

## Skills
- Flutter theming (ThemeData, ColorScheme)
- BLoC/Riverpod state management for theme switching
- Color palette design for accessibility (WCAG AA minimum)
- Cross-platform testing (iOS + Android)

## Root Cause / Current State
**File:** `lib/config/app_theme.dart`, `lib/main.dart`, `lib/features/` (all feature screens)

**Issue:**
- No dark theme defined; app uses single light theme
- No theme provider/notifier to toggle between light/dark
- All screens hardcoded to light colors; no ThemeData abstraction
- No user preference persistence (SharedPreferences integration)

## Changes Required

### 1. Create Unified Theme Configuration
**File:** `lib/config/app_theme.dart`
- Define `AppTheme` class with static `lightTheme()` and `darkTheme()` methods
- Both return `ThemeData` with:
  - Consistent `ColorScheme` (light & dark palettes)
  - Typography unified (same `TextTheme`, `fontFamily`)
  - Component styles (`AppBarTheme`, `CardTheme`, `ElevatedButtonThemeData`, etc.)
  - Semantic colors for backgrounds, surfaces, overlays
- Extract all hardcoded colors → centralized palette constants

### 2. Create Theme Provider (Riverpod)
**File:** `lib/providers/theme_provider.dart`
- `themeNotifierProvider`: StateNotifier<bool> for isDarkMode flag
- `themeDataProvider`: Provider<ThemeData> that returns dark/light based on notifier
- Persist preference to SharedPreferences on toggle
- Load saved preference on app startup

### 3. Update main.dart
**File:** `lib/main.dart`
- Wrap `MaterialApp` with `Consumer` (Riverpod)
- Pass `themeData` from `themeDataProvider`
- Optional: Add `darkTheme` + `themeMode` for system theme detection initially

### 4. Add Theme Toggle UI
**File:** `lib/features/settings/presentation/screens/settings_screen.dart`
- Add `ListTile` or `SwitchListTile` for "Dark Mode"
- Call `themeNotifierProvider.notifier.state = !isDark` on toggle
- Display current theme status

### 5. Audit & Refactor Feature Screens
**Search:** `lib/features/**/presentation/screens/` and `widgets/`
- Replace all hardcoded colors (e.g., `Color(0xFF...)`, `Colors.white`, `Colors.black`) with:
  - `Theme.of(context).colorScheme.primary`
  - `Theme.of(context).colorScheme.surface`
  - `Theme.of(context).textTheme.bodyMedium?.color`
- Ensure text contrast ratios meet WCAG AA (4.5:1 for body text, 3:1 for large text)
- Use `Theme.of(context)` consistently instead of static color references

### 6. Test Coverage
- **Unit:** Theme provider state transitions (light → dark → light)
- **Widget:** Verify colors render correctly on both themes (golden tests or screenshot tests)
- **Integration:** Manual verification on iOS + Android emulators
- **Accessibility:** Check contrast ratios with Flutter DevTools Accessibility Inspector

## Done-When
- ✅ `AppTheme` class fully defined with both themes in `app_theme.dart`
- ✅ `themeNotifierProvider` created, persists to SharedPreferences
- ✅ `main.dart` updated to use `themeDataProvider` from Riverpod
- ✅ Settings screen shows working toggle; theme switches on tap
- ✅ All hardcoded colors replaced with `Theme.of(context)` equivalents
- ✅ No visual regression: light theme still renders identically
- ✅ Dark theme colors meet WCAG AA contrast minimums (verified in design or automation)
- ✅ App restarts preserve user's last selected theme
- ✅ iOS + Android both render correctly (tested on emulator/device)
- ✅ Unit tests pass; theme toggle state transitions verified
