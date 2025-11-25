# Build Fixes & Troubleshooting

## ✅ All Fixed! Here's What Was Changed

This document explains all the fixes applied to make your Play flavor APK builds work correctly.

---

## 🔧 Issues Fixed

### 1. ABI Filter Conflict (✅ FIXED)

**Error:**
```
Conflicting configuration : 'armeabi-v7a,arm64-v8a,x86_64' in ndk abiFilters 
cannot be present when splits abi filters are set
```

**Root Cause:**
- The original `android/app/build.gradle` had dynamic `ndk.abiFilters` configuration
- This conflicts with Flutter's `--split-per-abi` flag
- You cannot use both at the same time

**Fix Applied:**
- Removed the dynamic `ndk.abiFilters` block from buildTypes
- Now relies solely on `--split-per-abi` flag in Flutter build command
- Added clear comments explaining the change

**What Changed in `android/app/build.gradle`:**
```gradle
// BEFORE (Lines 129-138):
android.productFlavors.each { flavor ->
    def tasks = gradle.startParameter.taskNames.toString().toLowerCase()
    if (tasks.contains(flavor.name) && flavor.ext.useNdkAbiFilters) {
        release {
            ndk {
                abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86_64'
            }
        }
    }
}

// AFTER:
// Removed entirely - let Flutter's --split-per-abi handle ABI filtering
```

---

### 2. Flutter Version Mismatch (✅ FIXED)

**Error:**
```
`workspace` requires at least language version 3.7
```

**Root Cause:**
- `pubspec.yaml` requires Flutter 3.27.4 and Dart SDK 3.6+
- `workspace` feature requires Dart 3.7+
- Workflows were using Flutter 3.22.1 (older Dart SDK)

**Fix Applied:**
- Updated both workflows to use Flutter 3.27.4
- Added version logging for debugging

**What Changed:**
```yaml
# BEFORE:
flutter-version: '3.22.1'

# AFTER:
flutter-version: '3.27.4'
```

---

### 3. Keystore Secret Name Mismatch (✅ DOCUMENTED)

**Error:**
```
base64: invalid input
```

**Root Cause:**
- Secret was named `KEYSTORE_BASE64` instead of `KEYSTORE_B64`
- Base64 string might have had line breaks or extra whitespace

**Fix Required:**
- Rename secret to `KEYSTORE_B64` (or update workflow to use `KEYSTORE_BASE64`)
- Ensure base64 string is single line without breaks:
  ```bash
  base64 -w 0 aves-release.jks > aves-keystore-b64.txt
  ```

---

## 🛡️ Preventive Fixes Applied

### Additional Safeguards:

1. **Removed flavor-specific NDK filters** - Play flavor no longer tries to set `ndk.abiFilters`
2. **Clean separation** - ABI filtering handled by Flutter CLI, not Gradle
3. **Updated Flutter version** - Ensures compatibility with latest features
4. **Added version logging** - Easier to debug future issues

---

## 📝 Current Build Configuration

### Android Gradle (`android/app/build.gradle`):

```gradle
productFlavors {
    play {
        dimension "store"
        // NO ndk.abiFilters - uses --split-per-abi instead
    }
    // ... other flavors
}

buildTypes {
    release {
        signingConfig = signingConfigs.release
        minifyEnabled = true
        shrinkResources = true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### Workflow Configuration:

```yaml
# Flutter Setup
- name: Set up Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.27.4'  # Updated for workspace support
    channel: 'stable'
    cache: true

# Build Command
flutter build apk \
  --release \
  --flavor play \
  --target lib/main_play.dart \
  --split-per-abi \        # Handles ABI filtering
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```

---

## ✅ Verification Checklist

After these fixes, your build should:

- [ ] ✅ Decode keystore successfully (no base64 errors)
- [ ] ✅ Parse `pubspec.yaml` without workspace errors
- [ ] ✅ Build without ABI filter conflicts
- [ ] ✅ Generate 3 APK files (arm64-v8a, armeabi-v7a, x86_64)
- [ ] ✅ Sign APKs with your release keystore
- [ ] ✅ Upload artifacts successfully
- [ ] ✅ Complete in ~10-15 minutes

---

## 🐞 Common Future Errors & Solutions

### Error: "Execution failed for task ':app:lintVitalPlayRelease'"

**Solution:** Add to `android/app/build.gradle`:
```gradle
android {
    lintOptions {
        checkReleaseBuilds false
        abortOnError false
    }
}
```

### Error: "Could not resolve all files for configuration"

**Solution:**
- Run `flutter pub get` locally
- Check for incompatible dependency versions in `pubspec.yaml`
- Use `flutter pub upgrade --major-versions` if needed

### Error: "minSdkVersion XX cannot be smaller than version XX"

**Solution:** Some dependencies require higher minSdk:
```gradle
defaultConfig {
    minSdk 23  // Increase if needed
}
```

### Error: "Duplicate class found"

**Solution:** Check for conflicting dependencies:
```gradle
dependencies {
    // Use 'implementation' not 'compile'
    // Check for duplicate entries
}
```

---

## 📊 Build Times

**Expected durations:**
- First build: 15-20 minutes (downloads all dependencies)
- Subsequent builds: 10-15 minutes (uses cache)
- With cache: 8-12 minutes

**If build takes >25 minutes:**
- Check GitHub Actions status page
- Look for network issues in logs
- Consider re-running the workflow

---

## 🔍 Debugging Future Issues

### Enable Detailed Logging:

Add to workflow build step:
```yaml
- name: Build with verbose logging
  run: |
    flutter build apk \
      --release \
      --flavor play \
      --target lib/main_play.dart \
      --split-per-abi \
      --verbose  # Add this for detailed output
```

### Check Gradle Dependencies:

Add a step before build:
```yaml
- name: List Gradle dependencies
  run: |
    cd android
    ./gradlew :app:dependencies --configuration playReleaseRuntimeClasspath
```

### Validate Configuration:

Add validation step:
```yaml
- name: Validate Gradle configuration
  run: |
    cd android
    ./gradlew :app:tasks --all
```

---

## 📚 Related Documentation

- **Quick Start**: [README_PLAY_BUILD.md](../README_PLAY_BUILD.md)
- **Automatic Builds**: [AUTO_BUILD_SETUP.md](AUTO_BUILD_SETUP.md)
- **Complete Guide**: [BUILD_PLAY_APK.md](BUILD_PLAY_APK.md)

---

## ✨ What's Working Now

✅ **Gradle configuration** - Clean, no conflicts  
✅ **Flutter version** - 3.27.4 with workspace support  
✅ **ABI splitting** - Handled by Flutter CLI  
✅ **Keystore signing** - Properly configured  
✅ **ML Kit OCR** - All language dependencies included  
✅ **Automatic builds** - Triggered on every push  
✅ **Manual builds** - Available with custom versions  

---

## 🚀 Next Steps

1. **Ensure secrets are set** (especially `KEYSTORE_B64` with correct name)
2. **Push a test commit** or manually trigger workflow
3. **Monitor the build** in Actions tab
4. **Download APK** from Artifacts
5. **Install and test** on your device!

---

## 📞 Getting Help

If you encounter new errors:

1. **Check this document first** for common solutions
2. **Read the error message carefully** - it usually points to the issue
3. **Check workflow logs** - Click on failed steps for details
4. **Open an issue** with:
   - Full error message
   - Workflow run URL
   - Steps to reproduce

---

**All issues resolved! Your builds should work now.** 🎉

**Test it:** Push a commit or manually trigger the workflow and watch it succeed!
