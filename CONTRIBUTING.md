# Contributing to Flutter Canvas

Thank you for your interest in contributing! This guide covers the development workflow.

## Development Setup

```bash
git clone https://github.com/fluttercanvas/flutter_canvas.git
cd flutter_canvas
flutter pub get
flutter test
flutter run -t example/lib/main.dart
```

## Architecture

The package follows Clean Architecture with clear separation between subsystems:

- **core/** — Cross-cutting concerns (exceptions, constants, extensions)
- **models/** — Domain objects (CanvasObject + 11 shapes)
- **controllers/** — Business logic orchestration (CanvasController)
- **widgets/** — Flutter UI layer (FlutterCanvas widget)
- **viewport/** — Camera/transform system
- **renderer/** — CustomPainter-based rendering engine
- **gestures/** — Input handling (touch, mouse, stylus, trackpad)
- **selection/** — Selection state and handles
- **layers/** — Layer management
- **history/** — Undo/redo with Command Pattern
- **commands/** — Individual command implementations
- **serialization/** — JSON import/export
- **export/** — Image/SVG export
- **collaboration/** — Real-time collaboration interfaces
- **utils/** — Shared utilities

## Adding a New Shape

1. Create `lib/models/shapes/canvas_myshape.dart`
2. Extend `CanvasObject`
3. Implement: `type`, `bounds`, `hitTest`, `render`, `clone`, `toJsonProperties`, `fromJson`
4. Register in `serialization/object_registry.dart`
5. Add export in `lib/flutter_canvas.dart`
6. Add tests in `test/unit/models_test.dart`

## Coding Standards

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- All public APIs must have dartdoc comments
- Target 90%+ test coverage
- No `// TODO` comments in production code
- Use `const` where possible

## Pull Request Process

1. Fork and create a feature branch
2. Write/update tests
3. Ensure `flutter test` passes
4. Update CHANGELOG.md
5. Submit PR with clear description

## Reporting Issues

Use GitHub Issues with:
- Flutter SDK version
- Device/platform
- Minimal reproduction code
- Expected vs actual behavior
