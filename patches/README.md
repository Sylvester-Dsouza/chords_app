# Plugin Patches

This directory contains patches for plugins that have compatibility issues with the latest Flutter SDK.

## flutter_local_notifications

The flutter_local_notifications plugin has several issues that need to be fixed:

1. **Namespace Issue**: The plugin's build.gradle file doesn't specify a namespace, which is required by newer versions of the Android Gradle Plugin.
2. **Linux Plugin Reference**: The plugin's pubspec.yaml references a non-existent Linux plugin.
3. **Ambiguous Method Reference**: The plugin's Java code has an ambiguous method reference to `bigLargeIcon`.

### Scripts

- `fix_namespace.sh`: Adds the namespace to the plugin's build.gradle file.
- `fix_pubspec.sh`: Removes the Linux plugin reference from the plugin's pubspec.yaml.
- `fix_java_code.sh`: Fixes the ambiguous method reference in the plugin's Java code.
- `fix_all.sh`: Runs all the above scripts.

### Usage

1. Run the fix script:
   ```bash
   cd chords_app
   ./patches/fix_all.sh
   ```

2. Clean the project and get dependencies:
   ```bash
   flutter clean
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Note

These fixes are temporary and will need to be reapplied if you update the plugin or clean your pub cache.

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
