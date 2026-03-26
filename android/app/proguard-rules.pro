# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Messaging (if used)
-keep class com.google.firebase.** { *; }

# Allow Flutter plugins to work with ProGuard
-dontwarn io.flutter.embedding.**
