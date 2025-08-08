TypeWriter Panel — Recipe: Add a route (page)

Intent: Create a new page and register it with auto_route for typed navigation.

Folder placement
- lib/routes/<feature>/
- Page files are typically named route.dart for index pages or based on feature.

Checklist
1) Create the page widget under lib/routes/... .
2) Annotate the page with @RoutePage() (auto_route).
3) Register the route in the central router configuration as a child of the appropriate parent route.
4) If the route requires auth, ensure the auth guard is applied.
5) Run codegen for routes.
6) Analyze.

Scaffold: Simple page
```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsRoute extends StatelessWidget {
  const SettingsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings content')),
    );
  }
}
```

Router registration (example)
```dart
// lib/routes/app_router.dart
import 'package:auto_route/auto_route.dart';
import 'package:typewriter_panel/routes/settings/route.dart';

@AutoRouterConfig(replaceInRouteName: 'Route,Page')
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true, children: [
          AutoRoute(page: SettingsRoute.page),
        ]),
      ];
}
```

Navigation usage
```dart
// Push
context.pushRoute(const SettingsRoute());

// Or navigate
context.router.navigate(const SettingsRoute());
```

Commands
- dart run build_runner build -d
- dart analyze

Notes
- Keep pages small; extract reusable widgets into lib/widgets/... .
- Co-locate feature-specific pages under lib/routes/<feature>/.
- Use typed arguments on the route constructor for parameters.

