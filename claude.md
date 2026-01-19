# Turbo Disc Golf - Claude Code Guidelines

## Disc Golf Terminology and Constants

### Putting Zones

When working with putting statistics, always reference the constants defined in `lib/utils/putting_constants.dart`:

- **C1 (Circle 1)**: Putts from 0-33 feet
  - Represents putts inside Circle 1, which is regulation for scoring
  - Use `c1MinDistance` (0.0) and `c1MaxDistance` (33.0)

- **C1X (Circle 1 Extended)**: Putts from 11-33 feet
  - Represents the outer portion of Circle 1, excluding gimme putts
  - Calculated by combining the '11-22 ft' and '22-33 ft' buckets
  - Use `c1xMinDistance` (11.0), `c1xMaxDistance` (33.0), and `c1xBuckets` list

- **C2 (Circle 2)**: Putts from 33-66 feet
  - Represents putts inside Circle 2, the outer regulation circle
  - Use `c2MinDistance` (33.0) and `c2MaxDistance` (66.0)

These definitions follow PDGA (Professional Disc Golf Association) standards.

## Build and Testing Workflow

**CRITICAL: Never automatically run iOS builds.**

- **DO NOT run**: `flutter build ios` or any iOS-specific build commands
- **The user will handle iOS builds manually**
- **DO run**: `flutter analyze` to check for code issues and warnings
- Running `flutter analyze` is encouraged after making code changes to catch potential problems early

## Code Style and Architecture

### Code Simplicity and Elegance

**CRITICAL: Always prioritize simple, elegant solutions over complex ones.**

#### Core Principles:

1. **Keep It Simple**: If you find yourself adding complex workarounds, step back and reconsider the approach
   - Removing and re-adding listeners is a code smell
   - Multiple nested callbacks indicate a design issue
   - If the logic is hard to explain, it's too complex

2. **Single Source of Truth**: Avoid conflicting sources of truth for the same data
   - Don't sync data between multiple state holders unless absolutely necessary
   - Clearly define which component owns each piece of state

3. **Predictable Data Flow**: State changes should follow a clear, unidirectional path
   - Parent → Child for data
   - Child → Parent for events
   - Avoid circular dependencies and callback chains

4. **Think Before Implementing**: Before writing code:
   - Understand the root cause of the problem
   - Consider if there's a simpler architectural approach
   - Ask: "Is this the simplest solution that could work?"

5. **Refactor When Complexity Grows**: If you're adding fixes on top of fixes:
   - Stop and refactor the underlying architecture
   - Simplify the data flow
   - Reduce the number of moving parts

6. **Clear Separation of Concerns**: Each component should have ONE clear responsibility
   - Voice service manages speech recognition
   - Cubit manages saved hole data
   - UI components display and capture user input
   - Don't mix concerns

7. **Never Use Negative Margins**: Negative margins cause layout errors and are a code smell
   - If you need to extend content past its container bounds, restructure the layout instead
   - Use proper padding/margin on parent containers
   - Consider using `Expanded` widgets or adjusting container padding
   - Negative margins often indicate a flawed layout hierarchy

**Why This Matters**: Complex code with multiple workarounds leads to bugs. Simple, well-architected code is easier to understand, maintain, and extend.

### Widget Composition Philosophy

**CRITICAL: Always prefer independent, stateless widgets over nested widget trees.**

**🚨 MAXIMUM NESTING LIMIT: 6 LEVELS - NO EXCEPTIONS 🚨**

The #1 rule of this codebase is: **Widget build methods must NEVER exceed 6 levels of nesting.** If you're approaching this limit, you MUST extract components immediately.

#### Core Principles:

- **Extract early and often**: Don't wait until nesting becomes a problem - extract proactively
- **6-level nesting is the absolute maximum**: Approach 6 levels? Extract immediately, no exceptions
- **Create widget functions**: Use `Widget _buildX(...)` for screen-specific sections
- **Create widget classes**: Use `class _Widget extends StatelessWidget` for reused components in the same file
- **Create separate files**: Move to `lib/components/` for cross-file reusability
- **Stateless by default**: Use StatelessWidget unless state is absolutely necessary
- **Single responsibility**: Each widget should have one clear purpose
- **Prefer composition**: Build complex UIs from simple, focused widgets

### Widget Extraction Pattern

❌ **AVOID: Highly nested build methods**
```dart
// DON'T DO THIS
Widget build(BuildContext context) {
  return Container(
    child: Column(
      children: [
        Container(
          child: Row(
            children: [
              Container(
                child: Text(...),
              ),
              Container(
                child: Icon(...),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

✅ **PREFER: Extracted, independent widgets**
```dart
// DO THIS
Widget build(BuildContext context) {
  return Column(
    children: [
      _HeaderSection(),
      _ContentSection(),
      _FooterSection(),
    ],
  );
}

// Extract into separate classes if reusable across screens
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _HeaderIcon(),
        const _HeaderTitle(),
      ],
    );
  }
}
```

### File Organization

**Import Order:**
1. Dart core libraries (`dart:*`)
2. Flutter libraries (`package:flutter/*`)
3. Third-party packages (alphabetically)
4. Local imports (alphabetically)

**Example:**
```dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:turbo_disc_golf/components/stat_card.dart';
import 'package:turbo_disc_golf/models/round.dart';
import 'package:turbo_disc_golf/services/analytics_service.dart';
```

### Widget Structure Guidelines

**CRITICAL: ALWAYS Extract Widgets - Never Allow Deep Nesting**

**ABSOLUTE RULE: Widget build methods must NEVER exceed 6 levels of nesting. Period.**

This is NON-NEGOTIABLE. Deep nesting makes code unreadable, unmaintainable, and error-prone. The moment you approach 6 levels, you MUST extract components.

#### MANDATORY Widget Extraction Rules:

**YOU MUST extract widgets in these situations:**

1. **Nesting Level Exceeds 5**: If you're about to create a 6th level of nesting, STOP and extract immediately
2. **Build Method Over 50 Lines**: Split into smaller widget functions or widget classes
3. **Complex Logic in Build**: Any non-trivial logic should be in its own widget
4. **Repeated Patterns**: Any UI pattern used more than once must become a widget
5. **Logical Grouping**: Related UI elements should be grouped into named widgets

#### Widget Extraction Strategy - Choose the Right Approach:

**1. Extract to Private Widget Methods (`Widget _buildX(...)`)**
   - Use for: Screen-specific components used only once in this file
   - Use for: Simple UI sections that don't need lifecycle management
   - Use for: Keeping related code together within one screen
   - Pattern: `Widget _buildHeader(BuildContext context) { ... }`

**2. Extract to Private StatelessWidget Classes (`class _WidgetName extends StatelessWidget`)**
   - Use for: Components reused multiple times within the SAME file
   - Use for: Components with complex logic or multiple helper methods
   - Use for: Better performance with const constructors
   - Use for: Components with clear, single responsibility
   - Pattern: Place at bottom of file with leading underscore
   - Example: `class _StatRow extends StatelessWidget { ... }`

**3. Extract to Public Widget Classes in Separate Files (`class WidgetName extends StatelessWidget`)**
   - Use for: Components used across MULTIPLE files or screens
   - Use for: Reusable UI components that form part of your design system
   - Use for: Complex components that deserve their own file
   - Location: `lib/components/` or `lib/widgets/`
   - Pattern: Create `lib/components/widget_name.dart`

**4. Extract to StatefulWidget**
   - Use for: Components managing their own local state
   - Use for: Components with animations, controllers, or subscriptions
   - Use for: State specific to the component, not lifted to parent
   - Can be private (`_WidgetName`) if only used in one file
   - Can be public if reused across multiple files

#### Decision Tree: How to Extract Your Widget

```
Is your build method approaching 6 levels of nesting OR over 50 lines?
  ↓ YES
Is this component used ONLY ONCE in this screen/file?
  ↓ YES
  → Extract to Private Widget Method: Widget _buildHeader(BuildContext context)

  ↓ NO (used multiple times in same file)
Is this component used in OTHER files/screens?
  ↓ NO (only in this file)
  → Extract to Private Widget Class: class _HeaderSection extends StatelessWidget

  ↓ YES (used across multiple files)
  → Extract to Public Widget in Separate File: lib/components/header_section.dart

Does the widget need to manage its own state?
  ↓ YES
  → Use StatefulWidget instead (private or public based on reusability)
```

#### CRITICAL: Avoid Duplicate Widget Components Across Files

**MANDATORY RULE: Before creating a new private widget class, ALWAYS search the codebase for similar implementations.**

If you find that the same or very similar private widget class (e.g., `_AnimatedMicrophoneButton`, `_SoundWaveIndicator`) exists in multiple files, this is a CODE SMELL that indicates the component should be extracted to a shared location.

**Why This Matters:**
- **DRY Principle**: Don't Repeat Yourself - duplicate code leads to maintenance nightmares
- **Consistency**: Changes to one implementation won't be reflected in duplicates
- **Bug Risk**: Fixing a bug in one place leaves the same bug in other copies
- **Wasted Space**: Multiple copies of identical code bloat the codebase

**How to Detect and Fix Duplicates:**

1. **Before creating a private widget class**, search for similar implementations:
   ```bash
   # Search for potential duplicates
   grep -r "class _AnimatedMicrophoneButton" lib/
   grep -r "class _SoundWaveIndicator" lib/
   ```

2. **If you find duplicates across multiple files**, immediately extract to a shared component:

❌ **WRONG: Duplicate private classes in multiple files**
```dart
// In lib/screens/round_history/components/record_round_panel.dart
class _AnimatedMicrophoneButton extends StatelessWidget { ... }
class _SoundWaveIndicator extends StatefulWidget { ... }

// In lib/screens/round_processing/components/record_single_hole_panel.dart
class _AnimatedMicrophoneButton extends StatelessWidget { ... }  // DUPLICATE!
class _SoundWaveIndicator extends StatefulWidget { ... }  // DUPLICATE!
```

✅ **CORRECT: Extract to shared component file**
```dart
// Create lib/components/animated_microphone_button.dart
class AnimatedMicrophoneButton extends StatelessWidget {
  const AnimatedMicrophoneButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) { ... }
}

class SoundWaveIndicator extends StatefulWidget { ... }

// Now both files can import and use the shared component:
// In lib/screens/round_history/components/record_round_panel.dart
import 'package:turbo_disc_golf/components/animated_microphone_button.dart';

// In lib/screens/round_processing/components/record_single_hole_panel.dart
import 'package:turbo_disc_golf/components/animated_microphone_button.dart';
```

**Component Organization by Reusability:**
- `lib/components/buttons.dart` - Shared button components (AnimatedMicrophoneButton, etc.)
- `lib/components/indicators.dart` - Shared indicator components (LoadingIndicator, etc.)
- `lib/components/cards.dart` - Shared card components
- `lib/widgets/` - Complex, standalone widgets that deserve their own file

**Action Items When You Spot Duplicates:**
1. Search the codebase for the duplicate widget name
2. Compare implementations - are they identical or nearly identical?
3. If identical, extract to `lib/components/` immediately
4. If similar with minor differences, consider parameterizing the shared component
5. Update all files to import and use the shared component
6. Delete the duplicate private classes

This ensures a clean, maintainable codebase with single sources of truth for all reusable components.

#### Example: Splitting a Large Build Function

❌ **NEVER DO THIS: Deeply nested build method (violates 6-level rule)**
```dart
@override
Widget build(BuildContext context) {
  return Card(                                  // Level 1
    child: Padding(                             // Level 2
      padding: const EdgeInsets.all(16),
      child: Column(                            // Level 3
        children: [
          Row(                                  // Level 4
            children: [
              Container(                        // Level 5
                child: Column(                  // Level 6 - AT THE LIMIT!
                  children: [
                    Row(                        // Level 7 - VIOLATION! TOO DEEP!
                      children: [
                        Icon(Icons.star),       // Level 8 - UNACCEPTABLE!
                        Text('4.5'),
                      ],
                    ),
                  ],
                ),
              ),
              // ... This continues even deeper ...
            ],
          ),
        ],
      ),
    ),
  );
}
// This is UNREADABLE and UNMAINTAINABLE - extract immediately!
```

✅ **GOOD: Split into private widget methods (for screen-specific, single-use sections)**
```dart
@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context),      // Extract to method
          _buildContent(context),     // Extract to method
          _buildFooter(context),      // Extract to method
        ],
      ),
    ),
  );
}

// Screen-specific helper - used once
Widget _buildHeader(BuildContext context) {
  return Row(
    children: [
      const Icon(Icons.person),
      Text('User Stats', style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

// Screen-specific helper - used once
Widget _buildContent(BuildContext context) {
  return Column(
    children: [
      _buildStatRow('Score', '42'),
      _buildStatRow('Rating', '850'),
    ],
  );
}

Widget _buildStatRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _buildFooter(BuildContext context) {
  // Implementation
}
```

✅ **BETTER: Extract to private widget classes (for reuse within same file)**
```dart
@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _HeaderSection(),
          const _StatRow(label: 'Score', value: '42'),
          const _StatRow(label: 'Rating', value: '850'),
          const _StatRow(label: 'Rounds', value: '15'),
        ],
      ),
    ),
  );
}

// At bottom of file - used MULTIPLE TIMES in THIS file
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person),
        Text('User Stats', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
```

✅ **BEST: Extract to separate file (for use across MULTIPLE files)**
```dart
// In current screen file
@override
Widget build(BuildContext context) {
  return InfoCard(
    header: const InfoCardHeader(
      title: 'User Stats',
      icon: Icons.person,
    ),
    children: const [
      StatRow(label: 'Score', value: '42'),
      StatRow(label: 'Rating', value: '850'),
      StatRow(label: 'Rounds', value: '15'),
    ],
  );
}

// In lib/components/stat_row.dart - reusable across MULTIPLE screens
class StatRow extends StatelessWidget {
  const StatRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// In lib/components/info_card.dart
class InfoCard extends StatelessWidget {
  const InfoCard({
    Key? key,
    required this.header,
    required this.children,
  }) : super(key: key);

  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [header, ...children]),
      ),
    );
  }
}
```

#### 1. Use Private Widget Methods for Screen-Specific Components

For components that are only used within a single screen and don't need to be stateless widgets:

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          _buildContent(context),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          const ScreenTitle(),
          const ScreenSubtitle(),
        ],
      ),
    );
  }
}
```

#### 2. Extract Reusable Components into Separate Files

For components used across multiple screens:

```dart
// lib/components/stat_card.dart
class StatCard extends StatelessWidget {
  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
  }) : super(key: key);

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) Icon(icon),
            Text(title),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            if (subtitle != null) Text(subtitle!),
          ],
        ),
      ),
    );
  }
}
```

#### 3. Use Private Widgets for Internal Components

For components only used within one file but that should be stateless:

```dart
// Use leading underscore for file-private widgets
class _PositionListItem extends StatelessWidget {
  const _PositionListItem({required this.position});

  final Position position;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(position.name),
      subtitle: Text(position.value),
    );
  }
}
```

### State Management

#### BLoC/Cubit Pattern

**CRITICAL: Always use BlocProvider.of<T>(context) to access Cubits, NEVER use locator.get<T>()**

When accessing a Cubit or Bloc in a widget, you must use `BlocProvider.of<T>(context)` to properly leverage the widget tree and ensure proper lifecycle management.

❌ **WRONG: Using service locator to access Cubit**
```dart
class _MyScreenState extends State<MyScreen> {
  late final MyCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator.get<MyCubit>();  // NEVER DO THIS!
    _cubit.initialize();
  }
}
```

✅ **CORRECT: Using BlocProvider.of to access Cubit**
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late final MyCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = BlocProvider.of<MyCubit>(context);  // ALWAYS DO THIS!
    _cubit.initialize();
  }

  @override
  void dispose() {
    _cubit.cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyCubit, MyState>(
      builder: (context, state) {
        if (state is MyLoadingState) {
          return const LoadingScreen();
        } else if (state is MyErrorState) {
          return ErrorScreen(message: state.message);
        }

        return _buildContent(state);
      },
    );
  }
}
```

**Why this matters:**
- `BlocProvider.of<T>(context)` ensures the Cubit is obtained from the widget tree, maintaining proper context and lifecycle
- `locator.get<T>()` bypasses the widget tree and can lead to memory leaks and improper state management
- Using `BlocProvider.of` ensures that the Cubit is properly scoped to the widget and will be disposed when the widget is removed from the tree

#### Provider Pattern

```dart
// Use Selector for performance when only part of state is needed
Selector<AppStateModel, bool>(
  selector: (_, model) => model.isDarkMode,
  builder: (context, isDarkMode, child) {
    return ThemedWidget(darkMode: isDarkMode);
  },
)
```

#### ClearOnLogoutProtocol - Multi-User Support

**CRITICAL: All Cubits and Services that cache user-specific data MUST implement ClearOnLogoutProtocol.**

When a user logs out and another user logs in, all cached user-specific data must be cleared to prevent data leakage between users. Any Cubit or Service that stores user-specific data in memory must implement `ClearOnLogoutProtocol` and be registered in the logout cleanup system.

**When to implement ClearOnLogoutProtocol:**
- Cubit stores user-specific data (rounds, user profile, stats, etc.)
- Service caches user-specific information (courses, preferences, etc.)
- Component maintains state that should reset between users
- Any data structure that could leak information to the next logged-in user

**How to implement:**

1. **Import the protocol:**
```dart
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
```

2. **Implement the protocol in your Cubit/Service:**
```dart
class UserDataCubit extends Cubit<UserDataState> implements ClearOnLogoutProtocol {
  UserDataCubit() : super(const UserDataInitial());

  // Your cubit methods here...

  @override
  Future<void> clearOnLogout() async {
    // Reset state to initial
    emit(const UserDataInitial());

    // Clear any cached data
    _cachedData = null;

    // Cancel any active streams/subscriptions if needed
    await _subscription?.cancel();
  }
}
```

3. **Register in the logout cleanup list in `lib/main.dart`:**
```dart
// In _MyAppState.initState()
final List<ClearOnLogoutProtocol> clearOnLogoutComponents = [
  // Cubits
  _roundHistoryCubit,
  _userDataCubit,           // Add your cubit here
  _recordRoundCubit,

  // Services from locator
  locator.get<RoundParser>(),
  locator.get<BagService>(),
  locator.get<CourseSearchService>(),
  // Add your service here if applicable
];
```

**Important notes:**
- The `clearOnLogout()` method MUST be `async` (returns `Future<void>`)
- Clear ALL user-specific data in this method
- Reset state to initial/empty state
- Cancel any active subscriptions or streams
- This prevents data leakage when switching between user accounts

**Example: Complete implementation**
```dart
class RoundHistoryCubit extends Cubit<RoundHistoryState> implements ClearOnLogoutProtocol {
  RoundHistoryCubit() : super(const RoundHistoryInitial());

  final List<DGRound> _cachedRounds = [];
  StreamSubscription<List<DGRound>>? _roundsSubscription;

  Future<void> loadRounds() async {
    // Load user's rounds...
  }

  @override
  Future<void> clearOnLogout() async {
    // Cancel active subscriptions
    await _roundsSubscription?.cancel();
    _roundsSubscription = null;

    // Clear cached data
    _cachedRounds.clear();

    // Reset to initial state
    emit(const RoundHistoryInitial());
  }

  @override
  Future<void> close() {
    _roundsSubscription?.cancel();
    return super.close();
  }
}
```

**Why this matters:**
- **Security**: Prevents user data from leaking to the next logged-in user
- **Privacy**: Ensures complete data isolation between user sessions
- **Memory management**: Clears cached data when no longer needed
- **Clean state**: Each user starts with a fresh, empty state

### Performance Best Practices

1. **Use const constructors**: Always mark widgets as const when possible
   ```dart
   const StatCard(title: 'Score', value: '42')
   ```

2. **Extract expensive builds**: Move complex widgets into separate classes to prevent rebuilds
   ```dart
   // Extract this into its own widget to prevent unnecessary rebuilds
   const ComplexChart()
   ```

3. **Use keys appropriately**: Add keys when working with lists or when state needs to be preserved
   ```dart
   ListView.builder(
     itemBuilder: (context, index) => StatCard(
       key: ValueKey(items[index].id),
       data: items[index],
     ),
   )
   ```

4. **Lazy loading**: Use ListView.builder or CustomScrollView for long lists

5. **Use `.withValues(alpha: ...)` instead of `.withOpacity()`**: The `.withOpacity()` method is deprecated. Always use `.withValues(alpha: ...)` for color transparency.

   ✅ **CORRECT:**
   ```dart
   color: Colors.black.withValues(alpha: 0.5)
   color: const Color(0xFF4CAF50).withValues(alpha: 0.8)
   ```

   ❌ **DEPRECATED:**
   ```dart
   color: Colors.black.withOpacity(0.5)  // Don't use - deprecated
   ```

### Naming Conventions

- **Classes**: PascalCase (`RoundReviewScreen`, `StatCard`)
- **Files**: snake_case (`round_review_screen.dart`, `stat_card.dart`)
- **Variables/Functions**: camelCase (`currentRound`, `calculateScore`)
- **Private members**: prefix with underscore (`_cubit`, `_buildHeader`)
- **Constants**: camelCase with const (`const defaultPadding = 16.0`)
- **Enums**: PascalCase for type, camelCase for values (`BreakdownType.assets`)

### Variable Declaration

**Always use explicit type annotations for variables whenever possible.**

This improves code readability and makes types clear at a glance.

✅ **PREFER: Explicit type annotations**
```dart
final String userName = 'John Doe';
final int userAge = 25;
final List<String> tags = ['flutter', 'dart'];
final Map<String, dynamic> userData = {'name': 'John', 'age': 25};
```

❌ **AVOID: Type inference with var**
```dart
var userName = 'John Doe';  // Type not immediately clear
var userAge = 25;
var tags = ['flutter', 'dart'];
```

**Exceptions:**
- When the type is obvious from the right-hand side (e.g., constructors):
  ```dart
  final controller = TextEditingController();  // Type is obvious
  ```
- In loop variables where the type is clear from context:
  ```dart
  for (var item in items) { ... }  // Acceptable when item type is obvious
  ```

### Button Usage

**CRITICAL: Always use PrimaryButton from `lib/components/buttons/primary_button.dart` for action buttons.**

When creating buttons for user actions (submit, save, create, etc.), always use the PrimaryButton component instead of raw ElevatedButton or custom button implementations.

✅ **CORRECT: Use PrimaryButton**
```dart
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';

PrimaryButton(
  width: double.infinity,
  height: 56,
  label: 'Create Course',
  gradientBackground: const [Color(0xFF137e66), Color(0xFF1a9f7f)],
  fontSize: 18,
  fontWeight: FontWeight.bold,
  onPressed: _handleSubmit,
)
```

❌ **WRONG: Custom button implementations**
```dart
// Don't create custom button widgets
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [...]),
  ),
  child: ElevatedButton(...),
)
```

**Why PrimaryButton?**
- Consistent styling across the app
- Built-in haptic feedback
- Loading states
- Gradient support
- Proper disabled states
- Bounce animation
- Less code duplication

### Component Structure Template

```dart
/// Brief description of what this component does
class ComponentName extends StatelessWidget {
  const ComponentName({
    Key? key,
    required this.requiredParam,
    this.optionalParam,
    this.callback,
  }) : super(key: key);

  /// Documentation for public properties
  final String requiredParam;
  final int? optionalParam;
  final VoidCallback? callback;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Implementation
  }
}
```

### Error Handling

```dart
// Use specific error states
if (state is ErrorState) {
  return EmptyState(
    title: state.message ?? 'Error occurred',
    subtitle: 'Please try again',
    onRetry: _retryAction,
  );
}

// Provide user-friendly error messages
catch (e) {
  return const EmptyState(
    title: 'Network error',
    subtitle: 'Please check your connection and try again.',
  );
}
```

### Resource Management

```dart
class _MyScreenState extends State<MyScreen> {
  late Timer _refreshTimer;
  StreamSubscription? _subscription;
  final StreamController<bool> _controller = StreamController<bool>();

  @override
  void initState() {
    super.initState();
    _initTimer();
    _initSubscription();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }
}
```

### CustomScrollView and Slivers

Prefer CustomScrollView with Slivers for complex scrolling behavior:

```dart
CustomScrollView(
  controller: scrollController,
  physics: const AlwaysScrollableScrollPhysics(),
  slivers: [
    CupertinoSliverRefreshControl(
      onRefresh: _refreshData,
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
    ),
  ],
)
```

### Theme Usage

```dart
// Always use theme colors instead of hardcoded values
backgroundColor: Theme.of(context).colorScheme.surface,
textColor: Theme.of(context).textTheme.bodyLarge?.color,

// For custom colors, reference from a centralized color utility
import 'package:turbo_disc_golf/utils/colors.dart';
color: AppColors.primaryGreen,
```

### Analytics and Tracking

```dart
// Track user interactions for important events
onPressed: () {
  serviceLocator.get<AnalyticsService>().track(
    'Button Pressed',
    properties: {
      'Screen Name': screenName,
      'Button': 'Submit',
    },
  );
  _handleSubmit();
}
```

### Common Patterns to Follow

1. **Screen routing**: Define static route names and screen names
   ```dart
   class RoundReviewScreen extends StatefulWidget {
     static const String routeName = '/round-review';
     static const String screenName = 'Round Review';
   }
   ```

2. **Conditional UI**: Use state-based rendering
   ```dart
   if (state is LoadingState) {
     return const LoadingIndicator();
   } else if (state is ErrorState) {
     return ErrorWidget(error: state.error);
   }
   return ContentWidget(data: state.data);
   ```

3. **Empty states**: Always provide meaningful empty states
   ```dart
   if (items.isEmpty) {
     return const EmptyState(
       title: 'No rounds yet',
       subtitle: 'Start recording your first round!',
     );
   }
   ```

3. **Methods Inside Widget Classes**: Always put helper or Widget functions below the build() method. initState() and dispose() stay above the build method, as well as variable initialization.


## Summary Checklist

Before submitting code, verify:
- [ ] **Widget trees NEVER exceed 6 levels of nesting** (CRITICAL - this is mandatory)
- [ ] Build methods are concise (<50 lines)
- [ ] Large build methods are split into widget functions (`Widget _buildX(...)`) or widget classes
- [ ] Components used once in a file are extracted to private widget methods
- [ ] Components reused within the same file are extracted to private widget classes (`class _Widget`)
- [ ] Components used across multiple files are in separate files under `lib/components/` or `lib/widgets/`
- [ ] **No duplicate widget classes exist across multiple files** (search for duplicates first!)
- [ ] StatelessWidget is used unless state is required
- [ ] StatefulWidget is used when component needs local state management
- [ ] Const constructors are used where possible
- [ ] Variables use explicit type annotations (e.g., `final String name = 'value'`)
- [ ] **Action buttons use PrimaryButton from `lib/components/buttons/primary_button.dart`**
- [ ] Imports are organized correctly
- [ ] Resources are properly disposed
- [ ] Theme values are used instead of hardcoded colors
- [ ] Error states and empty states are handled
- [ ] Analytics tracking is added for user interactions
- [ ] **Cubits/Blocs are accessed using `BlocProvider.of<T>(context)`, NEVER `locator.get<T>()`**
- [ ] **Cubits and Services with user-specific data implement `ClearOnLogoutProtocol`** and are registered in main.dart
- [ ] **Never use negative margins** - restructure layout instead

---

# Analytics Logging Convention Guide for Turbo Disc Golf

## Overview

This guide establishes comprehensive, consistent conventions for logging user interactions in the Turbo Disc Golf app. All events follow a standardized format optimized for Mixpanel dashboard analysis.

## Core Principles

1. **Consistency**: All events use the same naming patterns and property structures
2. **Context-Rich**: Every event includes screen context and action details
3. **Comprehensive**: Track all user interactions (taps, screens, modals, navigation)
4. **Readable**: Event names and properties are human-readable and self-documenting
5. **Analyzable**: Properties are structured to enable segmentation and funnel analysis in Mixpanel

## Auto-Enriched Properties

The `LoggingService` automatically adds these properties to EVERY event:

```dart
{
  'user_id': '<firebase_uid>',      // Added automatically from AuthService
  'timestamp': '<iso8601_string>',  // Added automatically
}
```

**You should NEVER manually add these properties** - the service handles them.

## Standard Event Types

### 1. Screen Impression

**Event Name:** `Screen Impression`

**When to Track:** Automatically in every screen's `initState()` or `build()` method

**Required Properties:**
- `screen_name` (String) - Human-readable screen name from `static const screenName`
- `screen_class` (String) - Widget class name (e.g., 'RoundHistoryScreen')

**Optional Properties:**
- `previous_screen` (String) - Where the user came from (if known)
- `round_id` (String) - If viewing a specific round
- `course_name` (String) - If viewing a specific course
- `tab_name` (String) - If viewing a tab within a screen

**Example:**
```dart
locator.get<LoggingService>().track('Screen Impression', properties: {
  'screen_name': RoundHistoryScreen.screenName,
  'screen_class': 'RoundHistoryScreen',
});
```

---

### 2. Button Tapped

**Event Name:** `Button Tapped`

**When to Track:** On every button/interactive element tap (buttons, cards, list items, icons)

**Required Properties:**
- `screen_name` (String) - Current screen name
- `button_name` (String) - Descriptive button name (e.g., 'Create Round', 'Save Settings')
- `element_type` (String) - Type of element ('button', 'card', 'list_item', 'icon', 'fab')

**Optional Properties:**
- `button_location` (String) - Where on screen ('header', 'footer', 'body', 'floating')
- `round_id` (String) - If action relates to a specific round
- `course_name` (String) - If action relates to a specific course
- `item_index` (int) - If tapping a list item

**Example:**
```dart
onPressed: () {
  locator.get<LoggingService>().track('Button Tapped', properties: {
    'screen_name': RoundHistoryScreen.screenName,
    'button_name': 'Create Round',
    'element_type': 'button',
    'button_location': 'floating',
  });

  // Handle action
  _createNewRound();
}
```

---

### 3. Modal Opened

**Event Name:** `Modal Opened`

**When to Track:** When showing bottom sheets, dialogs, alerts, or modals

**Required Properties:**
- `screen_name` (String) - Screen that triggered the modal
- `modal_type` (String) - Type of modal ('bottom_sheet', 'dialog', 'alert', 'full_screen_modal')
- `modal_name` (String) - Descriptive modal name (e.g., 'Delete Round Confirmation', 'Course Search')

**Optional Properties:**
- `trigger_source` (String) - What triggered it ('button', 'auto', 'long_press')
- `round_id` (String) - If modal relates to a specific round

**Example:**
```dart
void _showDeleteConfirmation() {
  locator.get<LoggingService>().track('Modal Opened', properties: {
    'screen_name': RoundHistoryScreen.screenName,
    'modal_type': 'dialog',
    'modal_name': 'Delete Round Confirmation',
    'trigger_source': 'button',
  });

  showDialog(...);
}
```

---

### 4. Tab Changed

**Event Name:** `Tab Changed`

**When to Track:** When switching tabs in bottom navigation OR within a screen (like RoundReviewScreen)

**Required Properties:**
- `screen_name` (String) - Screen containing the tabs
- `tab_index` (int) - Zero-based tab index
- `tab_name` (String) - Human-readable tab name

**Optional Properties:**
- `previous_tab_index` (int) - Previous tab index
- `previous_tab_name` (String) - Previous tab name
- `tab_context` (String) - 'bottom_navigation' or 'screen_tabs'

**Example:**
```dart
void _onTabChanged(int index) {
  locator.get<LoggingService>().track('Tab Changed', properties: {
    'screen_name': 'Main Navigation',
    'tab_index': index,
    'tab_name': _getTabName(index),
    'previous_tab_index': _currentIndex,
    'previous_tab_name': _getTabName(_currentIndex),
    'tab_context': 'bottom_navigation',
  });

  setState(() => _currentIndex = index);
}
```

---

### 5. Navigation Action

**Event Name:** `Navigation Action`

**When to Track:** When navigating to a new screen (push, pop, replace)

**Required Properties:**
- `from_screen` (String) - Current screen name
- `to_screen` (String) - Destination screen name
- `action_type` (String) - Navigation type ('push', 'pop', 'replace', 'deep_link')

**Optional Properties:**
- `trigger` (String) - What triggered navigation ('button', 'back_button', 'deep_link')

**Example:**
```dart
void _navigateToRoundReview() {
  locator.get<LoggingService>().track('Navigation Action', properties: {
    'from_screen': RoundHistoryScreen.screenName,
    'to_screen': RoundReviewScreen.screenName,
    'action_type': 'push',
    'trigger': 'button',
  });

  Navigator.push(...);
}
```

---

### 6. Form Interaction

**Event Name:** `Form Interaction`

**When to Track:** When users interact with form fields, toggles, sliders

**Required Properties:**
- `screen_name` (String) - Current screen
- `field_name` (String) - Form field identifier
- `interaction_type` (String) - Type of interaction ('text_input', 'toggle', 'slider', 'dropdown', 'date_picker')

**Optional Properties:**
- `field_value` (String/int/bool) - The value (if not sensitive)
- `validation_passed` (bool) - If validation occurred

**Example:**
```dart
onChanged: (value) {
  locator.get<LoggingService>().track('Form Interaction', properties: {
    'screen_name': SettingsScreen.screenName,
    'field_name': 'Dark Mode',
    'interaction_type': 'toggle',
    'field_value': value,
  });

  _updateDarkMode(value);
}
```

---

## Screen Constants - Required Pattern

**EVERY screen MUST have these two static constants:**

```dart
class RoundHistoryScreen extends StatefulWidget {
  const RoundHistoryScreen({super.key});

  // REQUIRED: Human-readable name for analytics
  static const String screenName = 'Round History';

  // REQUIRED: Route path for navigation
  static const String routeName = '/round-history';

  @override
  State<RoundHistoryScreen> createState() => _RoundHistoryScreenState();
}
```

**Naming Conventions:**
- `screenName`: Title case, spaces (e.g., 'Round History', 'Settings', 'Round Review')
- `routeName`: Lowercase, hyphens, starts with `/` (e.g., '/round-history', '/settings', '/round-review')

**Why Both?**
- `screenName`: Used in analytics for human-readable reporting
- `routeName`: Used for navigation and deep linking

---

## Screen Impression Implementation Patterns

### Pattern 1: StatefulWidget (Preferred)

```dart
class RoundHistoryScreen extends StatefulWidget {
  const RoundHistoryScreen({super.key});

  static const String screenName = 'Round History';
  static const String routeName = '/round-history';

  @override
  State<RoundHistoryScreen> createState() => _RoundHistoryScreenState();
}

class _RoundHistoryScreenState extends State<RoundHistoryScreen> {
  @override
  void initState() {
    super.initState();

    // Track screen impression
    locator.get<LoggingService>().track('Screen Impression', properties: {
      'screen_name': RoundHistoryScreen.screenName,
      'screen_class': 'RoundHistoryScreen',
    });
  }

  @override
  Widget build(BuildContext context) {
    // Screen UI
  }
}
```

### Pattern 2: StatelessWidget

For StatelessWidget, track in the build method (will only track once per screen instance):

```dart
class SomeScreen extends StatelessWidget {
  const SomeScreen({super.key});

  static const String screenName = 'Some Screen';
  static const String routeName = '/some-screen';

  @override
  Widget build(BuildContext context) {
    // Track on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track('Screen Impression', properties: {
        'screen_name': SomeScreen.screenName,
        'screen_class': 'SomeScreen',
      });
    });

    return Scaffold(...);
  }
}
```

---

## Button Tracking Implementation Patterns

### Pattern 1: PrimaryButton (Existing Component)

```dart
PrimaryButton(
  width: double.infinity,
  height: 56,
  label: 'Create Round',
  onPressed: () {
    locator.get<LoggingService>().track('Button Tapped', properties: {
      'screen_name': RoundHistoryScreen.screenName,
      'button_name': 'Create Round',
      'element_type': 'button',
    });

    _createRound();
  },
)
```

### Pattern 2: IconButton

```dart
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: () {
    locator.get<LoggingService>().track('Button Tapped', properties: {
      'screen_name': RoundHistoryScreen.screenName,
      'button_name': 'Settings',
      'element_type': 'icon',
      'button_location': 'header',
    });

    _navigateToSettings();
  },
)
```

### Pattern 3: Card/List Item Tap

```dart
GestureDetector(
  onTap: () {
    locator.get<LoggingService>().track('Button Tapped', properties: {
      'screen_name': RoundHistoryScreen.screenName,
      'button_name': 'Round Card',
      'element_type': 'card',
      'round_id': round.id,
      'course_name': round.courseName,
      'item_index': index,
    });

    _viewRound(round);
  },
  child: RoundCard(round: round),
)
```

### Pattern 4: FloatingActionButton

```dart
FloatingActionButton(
  onPressed: () {
    locator.get<LoggingService>().track('Button Tapped', properties: {
      'screen_name': RoundHistoryScreen.screenName,
      'button_name': 'Add Round',
      'element_type': 'fab',
      'button_location': 'floating',
    });

    _showRecordOptions();
  },
  child: const Icon(Icons.add),
)
```

---

## Modal Tracking Patterns

### Pattern 1: Bottom Sheet

```dart
void _showRoundOptions() {
  locator.get<LoggingService>().track('Modal Opened', properties: {
    'screen_name': RoundHistoryScreen.screenName,
    'modal_type': 'bottom_sheet',
    'modal_name': 'Round Options',
    'trigger_source': 'button',
  });

  showModalBottomSheet(
    context: context,
    builder: (context) => RoundOptionsSheet(),
  );
}
```

### Pattern 2: Dialog

```dart
void _showDeleteConfirmation() {
  locator.get<LoggingService>().track('Modal Opened', properties: {
    'screen_name': RoundHistoryScreen.screenName,
    'modal_type': 'dialog',
    'modal_name': 'Delete Confirmation',
    'trigger_source': 'button',
  });

  showDialog(
    context: context,
    builder: (context) => AlertDialog(...),
  );
}
```

### Pattern 3: Full-Screen Modal

```dart
void _openCourseSearch() {
  locator.get<LoggingService>().track('Modal Opened', properties: {
    'screen_name': RecordRoundScreen.screenName,
    'modal_type': 'full_screen_modal',
    'modal_name': 'Course Search',
    'trigger_source': 'button',
  });

  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => CourseSearchScreen(),
    ),
  );
}
```

---

## Tab Tracking Patterns

### Pattern 1: Bottom Navigation (MainWrapper)

```dart
class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    final String currentTabName = _getTabName(_currentIndex);
    final String newTabName = _getTabName(index);

    locator.get<LoggingService>().track('Tab Changed', properties: {
      'screen_name': 'Main Navigation',
      'tab_index': index,
      'tab_name': newTabName,
      'previous_tab_index': _currentIndex,
      'previous_tab_name': currentTabName,
      'tab_context': 'bottom_navigation',
    });

    setState(() => _currentIndex = index);
  }

  String _getTabName(int index) {
    switch (index) {
      case 0: return 'Home';
      case 1: return 'Stats';
      case 2: return 'Form Analysis';
      case 3: return 'Settings';
      default: return 'Unknown';
    }
  }
}
```

### Pattern 2: Screen Tabs (RoundReviewScreen)

```dart
class _RoundReviewScreenState extends State<RoundReviewScreen> {
  int _currentTabIndex = 0;

  void _onTabChanged(int index) {
    locator.get<LoggingService>().track('Tab Changed', properties: {
      'screen_name': RoundReviewScreen.screenName,
      'tab_index': index,
      'tab_name': _tabs[index].name,
      'previous_tab_index': _currentTabIndex,
      'previous_tab_name': _tabs[_currentTabIndex].name,
      'tab_context': 'screen_tabs',
      'round_id': widget.round.id,
    });

    setState(() => _currentTabIndex = index);
  }
}
```

---

## Implementation Checklist

When implementing analytics in a screen:

### Required Steps

1. **Add screen constants:**
   - [ ] Add `static const String screenName = '...'`
   - [ ] Add `static const String routeName = '/...'`

2. **Track screen impression:**
   - [ ] Add tracking in `initState()` (StatefulWidget) or `build()` (StatelessWidget)
   - [ ] Include `screen_name` and `screen_class` properties

3. **Track all button/tap interactions:**
   - [ ] Add tracking to every `onPressed`, `onTap`, `onLongPress`
   - [ ] Include `screen_name`, `button_name`, `element_type`
   - [ ] Add context properties (round_id, course_name, etc.) where relevant

4. **Track modals:**
   - [ ] Add tracking before showing bottom sheets
   - [ ] Add tracking before showing dialogs
   - [ ] Add tracking before full-screen modals
   - [ ] Include `modal_type`, `modal_name`, `trigger_source`

5. **Track tab changes:**
   - [ ] Add tracking to tab change handlers
   - [ ] Include current and previous tab info

### Optional Context Properties

Add these when relevant:
- [ ] `round_id` - When viewing/editing a specific round
- [ ] `course_name` - When viewing/editing a specific course
- [ ] `item_index` - When tapping list items
- [ ] `previous_screen` - When navigating between screens

---

## Property Naming Standards

### Casing
- Use **snake_case** for all property keys: `screen_name`, `button_name`, `tab_index`
- Use **Title Case** for human-readable values: `'Round History'`, `'Create Round'`

### Common Property Names

**Screen Context:**
- `screen_name` - Current screen (from static const)
- `screen_class` - Widget class name
- `previous_screen` - Previous screen name

**Action Context:**
- `button_name` - Button label or description
- `element_type` - Type of interactive element
- `button_location` - Where on screen

**Navigation Context:**
- `tab_index` - Tab number (0-based)
- `tab_name` - Tab label
- `tab_context` - Tab location ('bottom_navigation', 'screen_tabs')
- `from_screen` - Origin screen
- `to_screen` - Destination screen

**Content Context:**
- `round_id` - Round identifier
- `course_name` - Course name
- `item_index` - List position
- `modal_name` - Modal identifier
- `modal_type` - Modal style

### Reserved Properties (Auto-Added by LoggingService)

**NEVER manually add these:**
- `user_id` - Auto-added from AuthService
- `timestamp` - Auto-added as ISO8601

---

## Mixpanel Dashboard Organization

### Recommended Report Structure

**1. Screen Funnel**
- Event: `Screen Impression`
- Group by: `screen_name`
- Shows user flow through app

**2. Button Engagement**
- Event: `Button Tapped`
- Breakdown by: `button_name`, `screen_name`
- Shows most-used features

**3. Tab Usage**
- Event: `Tab Changed`
- Breakdown by: `tab_name`, `tab_context`
- Shows navigation patterns

**4. Modal Engagement**
- Event: `Modal Opened`
- Breakdown by: `modal_name`, `modal_type`
- Shows feature discovery

### Key Metrics to Track

1. **Daily Active Users (DAU)** - Unique users with any event
2. **Screen Impressions per User** - Average screens viewed per session
3. **Most Popular Screens** - `Screen Impression` grouped by `screen_name`
4. **Top Actions** - `Button Tapped` grouped by `button_name`
5. **Tab Switching Rate** - `Tab Changed` frequency
6. **Modal Conversion** - Users who open modals vs complete actions

### Segmentation Strategies

**By Screen:**
```
Event: Button Tapped
Filter: screen_name = "Round History"
Group by: button_name
```

**By Action:**
```
Event: Button Tapped
Filter: button_name = "Create Round"
Group by: screen_name
```

**Funnel Example:**
```
1. Screen Impression (screen_name = "Round History")
2. Button Tapped (button_name = "Create Round")
3. Screen Impression (screen_name = "Record Round")
4. Button Tapped (button_name = "Save Round")
5. Screen Impression (screen_name = "Round Review")
```

---

## Testing Your Implementation

### Manual Testing Checklist

1. **Check console logs:**
   - [ ] Run the app in debug mode
   - [ ] Navigate through screens
   - [ ] Verify console shows: `[LoggingService] Tracking: Screen Impression`
   - [ ] Verify console shows: `[LoggingService] Tracking: Button Tapped`

2. **Check Mixpanel dashboard:**
   - [ ] Wait 1-2 minutes for events to appear
   - [ ] Go to Mixpanel → Events
   - [ ] Verify events appear with correct properties
   - [ ] Verify `user_id` is populated (if logged in)
   - [ ] Verify `timestamp` is correct

3. **Test edge cases:**
   - [ ] Test with no internet (events should queue)
   - [ ] Test after logout (user_id should clear)
   - [ ] Test rapid taps (should track all)

### Common Issues

**Events not appearing in Mixpanel:**
- Check `.env` has correct `MIXPANEL_PROJECT_TOKEN`
- Check console for `[MixpanelProvider] Successfully initialized`
- Check internet connection
- Wait 1-2 minutes for events to sync

**Missing user_id:**
- Ensure user is logged in
- Check `AuthService.currentUid` returns a value
- Verify `LoggingService.initialize()` was called after login

**Duplicate screen impressions:**
- Use `initState()` for StatefulWidget, not `build()`
- For StatelessWidget, use `addPostFrameCallback` to track once

---

## Quick Reference: All Screen Names

Based on codebase exploration, here are the screens that need constants added:

### Authentication Screens
- `LandingScreen` → screenName: `'Landing'`, routeName: `'/landing'`
- `LoginScreen` → screenName: `'Login'`, routeName: `'/login'`
- `SignUpScreen` → screenName: `'Sign Up'`, routeName: `'/sign-up'`

### Onboarding
- `OnboardingScreen` → screenName: `'Onboarding'`, routeName: `'/onboarding'`
- `FeatureWalkthroughScreen` → screenName: `'Feature Walkthrough'`, routeName: `'/feature-walkthrough'`

### Main Navigation Screens
- `RoundHistoryScreen` → screenName: `'Round History'`, routeName: `'/round-history'`
- `StatsScreen` → screenName: `'Stats'`, routeName: `'/stats'`
- `FormAnalysisHistoryScreen` → screenName: `'Form Analysis History'`, routeName: `'/form-analysis-history'`
- `SettingsScreen` → screenName: `'Settings'`, routeName: `'/settings'`

### Round Management
- `RecordRoundScreen` → screenName: `'Record Round'`, routeName: `'/record-round'`
- `RecordRoundStepsScreen` → screenName: `'Record Round Steps'`, routeName: `'/record-round-steps'`
- `RoundProcessingLoadingScreen` → screenName: `'Round Processing'`, routeName: `'/round-processing'`
- `RoundReviewScreen` → screenName: `'Round Review'`, routeName: `'/round-review'`
- `ImportScoreScreen` → screenName: `'Import Score'`, routeName: `'/import-score'`

### Form Analysis
- `FormAnalysisRecordingScreen` → screenName: `'Form Analysis Recording'`, routeName: `'/form-analysis-recording'`
- `FormAnalysisDetailScreen` → screenName: `'Form Analysis Detail'`, routeName: `'/form-analysis-detail'`

### Courses
- `CreateCourseScreen` → screenName: `'Create Course'`, routeName: `'/create-course'`

### Round Review Tabs & Details
- `CoachTab` → screenName: `'Coach Tab'`, routeName: `'/coach-tab'`
- `CourseTab` → screenName: `'Course Tab'`, routeName: `'/course-tab'`
- `ScoreDetailScreen` → screenName: `'Score Detail'`, routeName: `'/score-detail'`
- `DrivesTab` → screenName: `'Drives Tab'`, routeName: `'/drives-tab'`
- `DrivingStatDetailScreen` → screenName: `'Driving Stat Detail'`, routeName: `'/driving-stat-detail'`
- `ThrowTypeDetailScreen` → screenName: `'Throw Type Detail'`, routeName: `'/throw-type-detail'`
- `GenericStatsScreen` → screenName: `'Generic Stats'`, routeName: `'/generic-stats'`
- `MistakesTab` → screenName: `'Mistakes Tab'`, routeName: `'/mistakes-tab'`
- `PsychTab` → screenName: `'Psych Tab'`, routeName: `'/psych-tab'`
- `PuttingTab` → screenName: `'Putting Tab'`, routeName: `'/putting-tab'`
- `RoastTab` → screenName: `'Roast Tab'`, routeName: `'/roast-tab'`
- `ScoresTab` → screenName: `'Scores Tab'`, routeName: `'/scores-tab'`
- `SkillsTab` → screenName: `'Skills Tab'`, routeName: `'/skills-tab'`
- `SummaryTab` → screenName: `'Summary Tab'`, routeName: `'/summary-tab'`

### Other
- `ForceUpgradeScreen` → screenName: `'Force Upgrade'`, routeName: `'/force-upgrade'`
- `RoundStoryView` → screenName: `'Round Story'`, routeName: `'/round-story'`
- `ShareJudgmentPreviewScreen` → screenName: `'Share Judgment Preview'`, routeName: `'/share-judgment-preview'`
- `ShareStoryPreviewScreen` → screenName: `'Share Story Preview'`, routeName: `'/share-story-preview'`
- `VoiceDetailInputScreen` → screenName: `'Voice Detail Input'`, routeName: `'/voice-detail-input'`

---

## Example: Full Screen Implementation

Here's a complete example of a screen with proper analytics:

```dart
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

class RoundHistoryScreen extends StatefulWidget {
  const RoundHistoryScreen({super.key});

  // REQUIRED: Screen constants for analytics and routing
  static const String screenName = 'Round History';
  static const String routeName = '/round-history';

  @override
  State<RoundHistoryScreen> createState() => _RoundHistoryScreenState();
}

class _RoundHistoryScreenState extends State<RoundHistoryScreen> {
  @override
  void initState() {
    super.initState();

    // Track screen impression
    locator.get<LoggingService>().track('Screen Impression', properties: {
      'screen_name': RoundHistoryScreen.screenName,
      'screen_class': 'RoundHistoryScreen',
    });
  }

  void _createRound() {
    locator.get<LoggingService>().track('Button Tapped', properties: {
      'screen_name': RoundHistoryScreen.screenName,
      'button_name': 'Create Round',
      'element_type': 'fab',
      'button_location': 'floating',
    });

    // Navigate to record round
    Navigator.pushNamed(context, RecordRoundScreen.routeName);
  }

  void _viewRound(String roundId, String courseName, int index) {
    locator.get<LoggingService>().track('Button Tapped', properties: {
      'screen_name': RoundHistoryScreen.screenName,
      'button_name': 'Round Card',
      'element_type': 'card',
      'round_id': roundId,
      'course_name': courseName,
      'item_index': index,
    });

    // Navigate to round review
    Navigator.pushNamed(
      context,
      RoundReviewScreen.routeName,
      arguments: roundId,
    );
  }

  void _showRoundOptions() {
    locator.get<LoggingService>().track('Modal Opened', properties: {
      'screen_name': RoundHistoryScreen.screenName,
      'modal_type': 'bottom_sheet',
      'modal_name': 'Round Options',
      'trigger_source': 'button',
    });

    showModalBottomSheet(
      context: context,
      builder: (context) => const RoundOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Round History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              locator.get<LoggingService>().track('Button Tapped', properties: {
                'screen_name': RoundHistoryScreen.screenName,
                'button_name': 'Settings',
                'element_type': 'icon',
                'button_location': 'header',
              });

              Navigator.pushNamed(context, SettingsScreen.routeName);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: rounds.length,
        itemBuilder: (context, index) {
          final round = rounds[index];
          return GestureDetector(
            onTap: () => _viewRound(round.id, round.courseName, index),
            child: RoundCard(round: round),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createRound,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## Summary

This convention provides:
- ✅ **Consistent event naming** across the entire app
- ✅ **Standardized properties** for easy Mixpanel segmentation
- ✅ **Screen identification** via required constants
- ✅ **Comprehensive tracking** of all user interactions
- ✅ **Clear implementation patterns** for common scenarios
- ✅ **Testable tracking** with console logging
- ✅ **Dashboard-ready events** optimized for Mixpanel analysis

All events automatically include `user_id` and `timestamp`, and every screen must have `screenName` and `routeName` constants for consistency.
