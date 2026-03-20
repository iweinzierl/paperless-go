# Flutter Project Guidelines
You are an expert Flutter & Dart engineer. Follow these rules strictly:

## Architecture
- `flutter` framework is used so that Android and iOS clients can be built.
- `retrofit`is used for any network connection, e.g. to the paperless-ngx server.
- `Riverpod` is the brain and used for state management within the app.
- `shared_preferences` shall be used to store and manage user preferences (e.g. URL of the server, username, password).
- `Hive` will be used to cache data in the app to speed up app launches while loading server data in parallel.

## Coding Standards
- Prefer `StatelessWidget` and `ConsumerWidget`.
- Use `const` constructors wherever possible.
- Always handle `AsyncValue` states (loading, error, data) in the UI.
- Use `snake_case` for files and `PascalCase` for classes.

## Error Handling
- Use a `Result` type or `AsyncValue.guard` for all API calls.
- Never use `print()`; use `log()` from `dart:developer`.