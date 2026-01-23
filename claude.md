# Turbo Disc Golf - Claude Code Guidelines

## Disc Golf Terminology

Always reference constants in `lib/utils/putting_constants.dart`:
- **C1 (Circle 1)**: 0-33 feet - `c1MinDistance` (0.0), `c1MaxDistance` (33.0)
- **C1X (Circle 1 Extended)**: 11-33 feet - `c1xMinDistance` (11.0), `c1xMaxDistance` (33.0), `c1xBuckets`
- **C2 (Circle 2)**: 33-66 feet - `c2MinDistance` (33.0), `c2MaxDistance` (66.0)

## Build Workflow

**CRITICAL: Never run iOS builds automatically.**
- ❌ DO NOT: `flutter build ios`
- ✅ DO: `flutter analyze` after code changes

## Code Architecture

### Simplicity Principles

1. **Keep It Simple**: Complex workarounds = code smell
2. **Single Source of Truth**: Define clear state ownership
3. **Predictable Data Flow**: Parent → Child data, Child → Parent events
4. **Think First**: Ask "Is this the simplest solution?"
5. **Refactor Complexity**: Stop adding fixes on fixes
6. **Separation of Concerns**: One responsibility per component
7. **No Negative Margins**: Restructure layout instead

### Widget Composition

**🚨 MAX 6-LEVEL NESTING - NO EXCEPTIONS 🚨**

**Extraction Strategy:**
- **Private Methods** `Widget _buildX()`: Screen-specific, used once
- **Private Classes** `class _Widget`: Reused in same file
- **Public Classes**: Used across files → `lib/components/`
- **StatefulWidget**: Manages own state

**Extract when:**
1. Nesting >5 levels
2. Build >50 lines
3. Complex logic
4. Repeated patterns
5. Before creating private class, search for duplicates

**Example:**
```dart
// ❌ WRONG: Deep nesting
Card(child: Padding(child: Column(children: [Row(children: [Container(child: Column(children: [Row(...)]))])])))

// ✅ CORRECT: Extracted
Widget build(BuildContext context) {
  return Card(child: Padding(child: Column(children: [_buildHeader(), _buildContent()])));
}
Widget _buildHeader() { /* ... */ }
```

### File Organization

1. Dart core (`dart:*`)
2. Flutter (`package:flutter/*`)
3. Third-party packages (alphabetically)
4. Local imports (alphabetically)

### State Management

**BLoC/Cubit:**
- ✅ ALWAYS: `BlocProvider.of<MyCubit>(context)`
- ❌ NEVER: `locator.get<MyCubit>()`

**ClearOnLogoutProtocol:**
All user-data Cubits/Services MUST implement to prevent data leakage.

```dart
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';

class UserDataCubit extends Cubit<UserDataState> implements ClearOnLogoutProtocol {
  @override
  Future<void> clearOnLogout() async {
    emit(const UserDataInitial());
    _cachedData = null;
    await _subscription?.cancel();
  }
}
```

Register in `lib/main.dart`:
```dart
final List<ClearOnLogoutProtocol> clearOnLogoutComponents = [
  _roundHistoryCubit, _userDataCubit, locator.get<BagService>(),
];
```

### Performance

1. Use const constructors
2. Extract expensive builds
3. Use keys for lists
4. ListView.builder for long lists
5. `.withValues(alpha: ...)` not `.withOpacity()`

### Card Spacing

**Best Practice: Use SizedBox between cards, not margins inside cards.**

- Standard spacing between cards: 8px
- Use `addRunSpacing()` from `lib/utils/layout_helpers.dart` for lists of cards

**Example:**
```dart
// ✅ CORRECT: Use addRunSpacing helper
ListView(
  children: addRunSpacing(
    [Card1(), Card2(), Card3()],
    runSpacing: 8,
    axis: Axis.vertical,
  ),
)

// ✅ CORRECT: Manual SizedBox
Column(
  children: [
    Card1(),
    const SizedBox(height: 8),
    Card2(),
  ],
)

// ❌ WRONG: Margins inside cards
Card(
  margin: EdgeInsets.only(bottom: 8), // Don't do this
  child: ...,
)
```

### Naming

- Classes: PascalCase (`RoundReviewScreen`)
- Files: snake_case (`round_review_screen.dart`)
- Variables/Functions: camelCase (`currentRound`)
- Private: underscore prefix (`_cubit`)
- Constants: camelCase const (`const defaultPadding = 16.0`)
- **UI Text/Headings**: Sentence case - capitalize first letter only (`'General tips'` not `'General Tips'`)

### Variables

**Use explicit types:**
```dart
// ✅ PREFER
final String userName = 'John Doe';
final List<String> tags = ['flutter'];

// ❌ AVOID
var userName = 'John Doe';
```

### Buttons

**CRITICAL: Use PrimaryButton from `lib/components/buttons/primary_button.dart`**

### Patterns

**Screen routing:**
```dart
class RoundReviewScreen extends StatefulWidget {
  static const String routeName = '/round-review';
  static const String screenName = 'Round Review';
}
```

**Navigation:**
✅ ALWAYS use `pushCupertinoRoute()` from `lib/utils/navigation_helpers.dart`
❌ NEVER use `Navigator.of(context).push(CupertinoPageRoute...` directly

```dart
// ✅ CORRECT
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

pushCupertinoRoute(context, const SettingsScreen());
pushCupertinoRoute(context, MyScreen(), pushFromBottom: true);

// ❌ WRONG
Navigator.of(context).push(
  CupertinoPageRoute(builder: (_) => const SettingsScreen()),
);
```

**Conditional UI:**
```dart
if (state is LoadingState) return const LoadingIndicator();
if (state is ErrorState) return ErrorWidget(error: state.error);
return ContentWidget(data: state.data);
```

**Methods:** Helpers/Widgets below build(), initState()/dispose() above

### Checklist

- [ ] Widget nesting ≤6 levels (MANDATORY)
- [ ] Build <50 lines
- [ ] Proper extraction strategy
- [ ] No duplicate widgets
- [ ] Const constructors
- [ ] Explicit types
- [ ] PrimaryButton for actions
- [ ] Organized imports
- [ ] Disposed resources
- [ ] Theme values
- [ ] Error/empty states
- [ ] BlocProvider.of (not locator.get)
- [ ] ClearOnLogoutProtocol
- [ ] No negative margins

---

# Analytics

## Principles

1. Consistency, 2. Context-Rich, 3. Comprehensive, 4. Analyzable

## Auto-Recorded by Mixpanel

**NEVER manually add these - Mixpanel records them automatically:**
- `user_id`: Set via `identify()` call on login
- `timestamp`: Recorded automatically by Mixpanel
- `screen_name`: Auto-added via scoped logger's base properties

## Event Types

### 1. Screen Impression
**When:** `initState()` or `build()`
**Required:** `screen_name`, `screen_class`
**Optional:** `previous_screen`, `round_id`, `course_name`, `tab_name`

```dart
locator.get<LoggingService>().track('Screen Impression', properties: {
  'screen_name': RoundHistoryScreen.screenName,
  'screen_class': 'RoundHistoryScreen',
});
```

### 2. Button Tapped
**When:** Every tap
**Event Name Format:** Include SPECIFIC button/action name in event - make it descriptive enough to know exactly what was pressed without looking at properties
**Properties:** Only contextual data - NO `button_name`, `element_type`, or `button_location`

**CRITICAL:** Event names must be SPECIFIC and SELF-DESCRIPTIVE:
- ✅ `'Create New Course Button Tapped'` - specific action
- ✅ `'Course Layout Selected'` - describes what happened
- ✅ `'Edit Layout Button Tapped'` - clear action
- ✅ `'Scorecard Parsed Successfully'` - outcome is clear
- ❌ `'Button Tapped'` with `{'button_name': 'Create Course'}` - generic, requires property lookup
- ❌ `'Form Interaction'` with `{'field_name': 'date_time'}` - not descriptive

**IMPORTANT:** Use scoped logger with base properties (see Implementation section).

```dart
onPressed: () {
  _logger.track('Create Round Button Tapped', properties: {
    'round_id': round.id,
    'item_index': index,
  });
  _createNewRound();
}
```

### 3. Modal Opened
**Required:** `screen_name`, `modal_type` ('bottom_sheet', 'dialog', 'alert', 'full_screen_modal'), `modal_name`
**Optional:** `trigger_source`, `round_id`

### 4. Tab Changed
**Required:** `screen_name`, `tab_index`, `tab_name`
**Optional:** `previous_tab_index`, `previous_tab_name`, `tab_context`

### 5. Navigation Action
**Required:** `from_screen`, `to_screen`, `action_type` ('push', 'pop', 'replace', 'deep_link')
**Optional:** `trigger`

### 6. Form Interaction
**Event Name Format:** Use SPECIFIC event names describing the interaction (e.g., 'Date Time Picker Confirmed', 'Course Name Field Changed')
**Properties:** Only contextual data - `screen_name` is auto-added via scoped logger
**Optional:** `field_value`, `validation_passed`

**Examples:**
- ✅ `'Beautiful Date Time Picker Confirmed'` with `{'date_changed': true}`
- ✅ `'Hole Description Cleared'` with `{'hole_number': 5}`
- ✅ `'Location Selected On Map'`
- ❌ `'Form Interaction'` with `{'field_name': 'date_time', 'interaction_type': 'date_picker'}` - too generic

## Screen Constants

**EVERY screen MUST have:**
```dart
static const String screenName = 'Round History';  // Title case
static const String routeName = '/round-history';   // Lowercase, hyphens
```

## Implementation

**StatefulWidget:**
```dart
@override
void initState() {
  super.initState();
  locator.get<LoggingService>().track('Screen Impression', properties: {
    'screen_name': RoundHistoryScreen.screenName,
    'screen_class': 'RoundHistoryScreen',
  });
}
```

**StatelessWidget:**
```dart
@override
Widget build(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    locator.get<LoggingService>().track('Screen Impression', properties: {
      'screen_name': SomeScreen.screenName, 'screen_class': 'SomeScreen',
    });
  });
  return Scaffold(...);
}
```

## Property Names

**Casing:**
- Keys: snake_case (`screen_name`, `button_name`)
- Values: Title Case ('Round History')

**Common:**
- Screen: `screen_name`, `screen_class`, `previous_screen`
- Action: `button_name`, `element_type`, `button_location`
- Nav: `tab_index`, `tab_name`, `from_screen`, `to_screen`
- Content: `round_id`, `course_name`, `item_index`, `modal_name`

## Checklist

**Required:**
1. Add `screenName` and `routeName`
2. Track screen impression
3. Track all taps
4. Track modals
5. Track tabs

**Optional Context:** `round_id`, `course_name`, `item_index`, `previous_screen`

## Screen Names

**Auth:** Landing, Login, Sign Up
**Main:** Round History, Stats, Form Analysis History, Settings
**Round:** Record Round, Round Review, Import Score
**Tabs:** Coach, Course, Drives, Mistakes, Psych, Putting, Roast, Scores, Skills, Summary

## Testing

1. Debug console: verify tracking logs
2. Mixpanel (wait 1-2 min)
3. Edge cases: offline, logout, rapid taps

**Issues:**
- No events: Check `.env` MIXPANEL_PROJECT_TOKEN
- No user_id: Verify login, LoggingService.initialize()
- Duplicates: initState() for Stateful, addPostFrameCallback for Stateless

## Mixpanel

**Metrics:**
1. DAU
2. Screen Impressions/User
3. Popular Screens
4. Top Actions
5. Tab Switching
6. Modal Conversion

**Funnel:**
```
Screen Impression (Round History) → Button Tapped (Create Round) →
Screen Impression (Record Round) → Button Tapped (Save Round) →
Screen Impression (Round Review)
```

---

## Summary

**Code:**
✅ 6-level max nesting
✅ Simple solutions
✅ Extraction strategy
✅ BlocProvider.of
✅ ClearOnLogoutProtocol
✅ No negative margins

**Analytics:**
✅ Consistent naming
✅ Standardized properties
✅ Screen constants
✅ Comprehensive tracking
✅ Auto-enriched user_id/timestamp
