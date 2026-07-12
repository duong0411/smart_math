# Keep Flutter / JNI entry points used by plugins (pdfrx, file_picker, etc.).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# pdfrx / pdfium JNI
-keep class com.github.myui.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter references Play Core deferred components; not used in this app.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
