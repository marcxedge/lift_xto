# Reglas conservadoras para que R8 no elimine código al que Flutter y sus
# plugins (sqflite, shared_preferences, path_provider) acceden vía JNI /
# generated plugin registrant en tiempo de ejecución.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
