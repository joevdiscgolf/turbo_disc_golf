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
- [ ] Imports are organized correctly
- [ ] Resources are properly disposed
- [ ] Theme values are used instead of hardcoded colors
- [ ] Error states and empty states are handled
- [ ] Analytics tracking is added for user interactions
- [ ] **Cubits/Blocs are accessed using `BlocProvider.of<T>(context)`, NEVER `locator.get<T>()`**
