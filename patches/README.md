# Plugin Patches

This directory contains patches for plugins that have compatibility issues with the latest Flutter SDK.

## flutter_local_notifications - REMOVED

The flutter_local_notifications plugin has been removed from the project due to compatibility issues.
We now use custom SnackBar implementations for notifications instead.

**Previous issues that led to removal:**
1. **Namespace Issue**: The plugin's build.gradle file didn't specify a namespace
2. **Linux Plugin Reference**: The plugin's pubspec.yaml referenced a non-existent Linux plugin
3. **Ambiguous Method Reference**: The plugin's Java code had ambiguous method references

**Current Solution**: Custom notification system using Flutter's built-in SnackBar and overlay widgets.

## sign_in_with_apple

The sign_in_with_apple plugin needs a namespace to be specified in its build.gradle file. To apply the patch:

1. Locate the plugin directory:
```
cd ~/.pub-cache/hosted/pub.dev/sign_in_with_apple-4.3.0/
```

2. Apply the patch:
```
patch -p1 < /path/to/chords_app/patches/sign_in_with_apple_fix.patch
```

### Alternative: Manual Fix

If the patch doesn't work, you can manually edit the plugin's build.gradle file:

1. Open `~/.pub-cache/hosted/pub.dev/sign_in_with_apple-4.3.0/android/build.gradle`
2. Update the Kotlin version to 1.8.10
3. Update the Android Gradle Plugin version to 7.3.0
4. Add the namespace to the android block:
   ```gradle
   android {
       compileSdkVersion 33

       namespace 'com.aboutyou.dart_packages.sign_in_with_apple'

       // rest of the configuration...
   }
   ```
