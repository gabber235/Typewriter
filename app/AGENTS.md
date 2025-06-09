# AGENT Instructions – App

The Flutter application provides a web interface for managing Typewriter projects.

## Environment Setup

On Linux install Flutter once by running:

```bash
./install_flutter_linux.sh
```

Run this script before executing any Flutter commands.
It adds `~/development/flutter/bin` to your `PATH`, so open a new shell or run
`source ~/.bashrc` after installation.

## Validate Changes

Install dependencies and build the web app:

```bash
flutter pub get
flutter build web
```

Run tests with:

```bash
flutter test
```

## Code Style

Follow standard Dart formatting using `flutter format` and keep files under 300 lines where possible.

