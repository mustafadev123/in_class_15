# API-to-Cloud Trivia Showdown

CSC 4360 In-Class Activity 15 implemented in Flutter. The app requests five
easy general-knowledge questions from Open Trivia Database, validates both the
HTTP status and API response code, decodes entity text, and represents loading,
error, question, feedback, and result states in the UI.

## Run and verify

```console
flutter pub get
flutter run
flutter analyze
flutter test
```

Android includes the `INTERNET` permission required for the live request.

## Cloud boundary

No instructor endpoint was supplied, so **Simulate leaderboard sync** is an
explicit classroom simulation. It waits asynchronously and presents the final
score, but sends no network write and never claims remote persistence. A real
write requires an instructor-provided endpoint, agreed JSON payload, and UI
states based on the server's actual response.
