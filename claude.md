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

### Widget Composition Philosophy

**CRITICAL: Always prefer independent, stateless widgets over nested widget trees.**

- **Extract components early**: If a widget tree exceeds 2-3 levels of nesting, extract it into a separate widget
- **Create reusable components**: Build generic, configurable widgets that can be used across multiple screens
- **Stateless by default**: Use StatelessWidget unless state is absolutely necessary
- **Single responsibility**: Each widget should have one clear purpose

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

**CRITICAL: Avoid Super Nested and Huge Widget Build Functions**

Build methods should be concise and readable. If your build method exceeds ~50 lines or has more than 3-4 levels of nesting, split it up.

#### When to Extract:

1. **Extract to private Widget methods** (`Widget _buildX(...)`) when:
   - The widget is only used in this screen/file
   - It's a simple helper that doesn't need lifecycle management
   - You want to keep related code together

2. **Extract to StatelessWidget** when:
   - The widget might be reused elsewhere
   - It has complex logic or multiple helper methods
   - You want better performance (const constructors, less rebuilds)
   - The component has a clear, single responsibility

3. **Extract to StatefulWidget** when:
   - The component needs to manage its own local state
   - It has animations, controllers, or subscriptions
   - The state is specific to this component and shouldn't be lifted up
   - The component is complex enough to benefit from modular state management

#### Example: Splitting a Large Build Function

❌ **AVOID: Massive, deeply nested build method**
```dart
@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                child: Column(
                  children: [
                    Text('Title'),
                    Text('Subtitle'),
                    Row(
                      children: [
                        Icon(Icons.star),
                        Text('4.5'),
                      ],
                    ),
                  ],
                ),
              ),
              // ... 50+ more lines
            ],
          ),
          // ... 100+ more lines
        ],
      ),
    ),
  );
}
```

✅ **PREFER: Split into logical sections**
```dart
@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context),
          _buildContent(context),
          _buildFooter(context),
        ],
      ),
    ),
  );
}

Widget _buildHeader(BuildContext context) {
  return Row(
    children: [
      const _HeaderIcon(),
      _HeaderText(),
      const _HeaderRating(),
    ],
  );
}

Widget _buildContent(BuildContext context) {
  // Implementation
}

Widget _buildFooter(BuildContext context) {
  // Implementation
}
```

✅ **EVEN BETTER: Extract reusable components**
```dart
@override
Widget build(BuildContext context) {
  return InfoCard(
    header: const InfoCardHeader(
      title: 'Title',
      subtitle: 'Subtitle',
      rating: 4.5,
    ),
    content: const InfoCardContent(...),
    footer: const InfoCardFooter(...),
  );
}

// In separate file: lib/components/info_card.dart
class InfoCard extends StatelessWidget {
  const InfoCard({
    Key? key,
    required this.header,
    required this.content,
    required this.footer,
  }) : super(key: key);

  final Widget header;
  final Widget content;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [header, content, footer],
        ),
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
    _cubit = BlocProvider.of<MyCubit>(context);
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

## Summary Checklist

Before submitting code, verify:
- [ ] Build methods are concise (<50 lines) and not deeply nested (≤3-4 levels)
- [ ] Large build methods are split into smaller Widget methods or StatelessWidgets
- [ ] Components are extracted from nested widget trees
- [ ] Reusable widgets are in separate files under `lib/components/` or `lib/widgets/`
- [ ] StatelessWidget is used unless state is required
- [ ] StatefulWidget is used when component needs local state management
- [ ] Const constructors are used where possible
- [ ] Variables use explicit type annotations (e.g., `final String name = 'value'`)
- [ ] Imports are organized correctly
- [ ] Resources are properly disposed
- [ ] Theme values are used instead of hardcoded colors
- [ ] Error states and empty states are handled
- [ ] Analytics tracking is added for user interactions
- [ ] Widget trees don't exceed 3-4 levels of nesting
