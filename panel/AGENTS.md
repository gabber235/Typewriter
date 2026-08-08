# Panel guidance

## Dart imports

For internal panel APIs, always prefer the main package barrel:

```dart
import "package:typewriter_panel/typewriter_panel.dart";
```

Do not replace the main barrel with individual `typewriter_panel` imports.
External package imports remain direct.
