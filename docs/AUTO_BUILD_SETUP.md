# Automatic Play Flavor APK Build Setup

🤖 **Your branch is now configured to automatically build Play flavor APKs whenever you push code!**

## 🎯 How It Works

### Automatic Builds

Every time you push changes to the `feature/ocr-integration` branch, GitHub Actions will automatically:

1. ✅ Build a signed Play flavor APK
2. ✅ Create split APKs for each architecture (arm64-v8a, armeabi-v7a, x86_64)
3. ✅ Upload APKs as artifacts
4. ✅ Keep APKs for 30 days

### What Triggers a Build?

✅ **Builds happen when you push**:
- Code changes to `.dart` files
- Android configuration changes
- Dependency updates in `pubspec.yaml`
- Changes to `android/` directory

❌ **Builds are skipped for**:
- Documentation changes (`.md` files)
- Updates to `docs/` folder
- README updates

This saves build time and resources!

## 🔑 Prerequisites (One-Time Setup)

### Required GitHub Secrets

You **must** set up these secrets for automatic builds to work:

1. Go to: https://github.com/osphvdhwj/aves/settings/secrets/actions
2. Add these secrets:

| Secret Name | Description | Required |
|------------|-------------|----------|
| `KEYSTORE_B64` | Base64-encoded keystore file | ✅ Yes |
| `KEYSTORE_PASSWORD` | Keystore password | ✅ Yes |
| `KEY_ALIAS` | Key alias name | ✅ Yes |
| `KEY_PASSWORD` | Key password | ✅ Yes |
| `GOOGLE_API_KEY` | Google API key | ❌ Optional |

### Creating a Keystore

If you don't have a keystore, create one using Termux:

```bash
# Install Java
pkg install openjdk-17

# Generate keystore
keytool -genkey -v \
  -keystore ~/aves-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias aves-key

# Follow the prompts and remember your passwords!

# Convert to base64 for GitHub Secret
base64 ~/aves-release.jks > ~/aves-keystore-b64.txt

# View the base64 string (copy this to KEYSTORE_B64 secret)
cat ~/aves-keystore-b64.txt
```

**Important**: Save your keystore passwords securely! You'll need them for the GitHub secrets.

## 🚀 Using Automatic Builds

### Scenario 1: Making Code Changes

```bash
# Make your changes to the code
# Then commit and push

git add .
git commit -m "feat: Add new OCR feature"
git push origin feature/ocr-integration

# 🎉 Build starts automatically!
```

### Scenario 2: Checking Build Status

1. Go to: https://github.com/osphvdhwj/aves/actions
2. You'll see "Auto Build Play APK on Push" workflow running
3. Click on the workflow run to see progress
4. Build takes ~10-15 minutes

### Scenario 3: Downloading APKs

1. Wait for build to complete (✅ green checkmark)
2. Click on the completed workflow run
3. Scroll to **Artifacts** section
4. Download the APK for your device:
   - **arm64-v8a** → Modern phones (recommended)
   - **armeabi-v7a** → Older 32-bit devices
   - **x86_64** → Emulators

## 📝 APK Naming Convention

APKs are automatically named with:

```
aves-play-[DATE]-[TIME]-[COMMIT]-[ARCH].apk
```

Example:
```
aves-play-20251125-1430-a3f2b1c-arm64-v8a.apk
         │        │    │       └─ Architecture
         │        │    └─────── Short commit hash
         │        └──────────── Time (24h format)
         └─────────────────── Date (YYYYMMDD)
```

This makes it easy to track which code version each APK contains!

## 🛠️ Workflow Configuration

### Build Settings

- **Flutter Version**: 3.22.1
- **Java Version**: 17
- **Build Type**: Release (signed & obfuscated)
- **Flavor**: Play (Google Play Services)
- **Split**: Per-ABI (smaller APKs)
- **Artifact Retention**: 30 days

### What Gets Built?

Each push creates 3 APK files:

1. **arm64-v8a** (~50-60 MB)
   - For modern Android phones (2015+)
   - 64-bit ARM architecture
   - **Recommended for most users**

2. **armeabi-v7a** (~45-55 MB)
   - For older Android phones (pre-2015)
   - 32-bit ARM architecture

3. **x86_64** (~55-65 MB)
   - For Android emulators
   - Some x86-based tablets

## ⚙️ Advanced Usage

### Manual Builds

You can still trigger manual builds:

1. Go to: https://github.com/osphvdhwj/aves/actions
2. Select "Build Play Flavor Release APK" (manual workflow)
3. Click "Run workflow"
4. Enter a custom version name
5. Click "Run workflow" button

### Modifying the Workflow

The workflow file is located at:
```
.github/workflows/auto-build-play-apk.yml
```

You can customize:
- Build triggers (branches, paths)
- APK naming
- Artifact retention period
- Build configuration

### Disabling Auto-Builds

To temporarily disable automatic builds:

1. Go to: https://github.com/osphvdhwj/aves/actions
2. Click "Auto Build Play APK on Push"
3. Click the "⋮" menu (top right)
4. Select "Disable workflow"

Re-enable anytime by clicking "Enable workflow"

## 🐞 Troubleshooting

### Build Fails: "KEYSTORE_B64 not set"

**Problem**: Keystore secret is missing

**Solution**:
1. Go to repository settings
2. Navigate to Secrets → Actions
3. Add the `KEYSTORE_B64` secret
4. Re-run the failed workflow

### Build Fails: "Keystore password incorrect"

**Problem**: Wrong password in secrets

**Solution**:
1. Verify your keystore password is correct
2. Update `KEYSTORE_PASSWORD` and `KEY_PASSWORD` secrets
3. Re-run the workflow

### Build Succeeds but No Artifacts

**Problem**: APK files not found

**Solution**:
1. Check workflow logs for build errors
2. Verify `lib/main_play.dart` exists
3. Ensure `android/app/build.gradle` has Play flavor configured

### "No space left on device"

**Problem**: GitHub runner out of space

**Solution**: This is rare. Re-run the workflow - GitHub will assign a fresh runner.

### Build Takes Too Long

**Normal**: 10-15 minutes for full build

**Slow (>20 min)**: Check GitHub Actions status page for incidents

## 📊 Build History

View all your builds:

1. Go to: https://github.com/osphvdhwj/aves/actions
2. Click "Auto Build Play APK on Push"
3. See complete history with:
   - Build status (✅ success, ❌ failed, 🟡 in progress)
   - Commit that triggered the build
   - Build duration
   - Available artifacts

## 📄 Build Artifacts

### Retention Policy

APKs are kept for **30 days** after the build.

After 30 days:
- Artifacts are automatically deleted
- Build logs remain available
- You can re-run the workflow to rebuild

### Downloading Old Builds

1. Go to Actions tab
2. Find the workflow run you want
3. Check if artifacts are still available (within 30 days)
4. Download if available

## 🆘 vs. Manual Workflow

| Feature | Automatic Build | Manual Workflow |
|---------|----------------|----------------|
| **Trigger** | Push to branch | Manual button click |
| **Custom version** | Auto-generated | User-specified |
| **Frequency** | Every code push | On-demand |
| **Best for** | Development, testing | Production releases |
| **Naming** | Date-time-commit | Custom version name |

**Use automatic** for regular development.

**Use manual** for official releases with version numbers.

## ✨ Benefits

✅ **No setup needed** - Just push code
✅ **Always up-to-date** - Latest code = latest APK
✅ **Track changes** - Each APK tied to specific commit
✅ **Test quickly** - APK ready in ~15 minutes
✅ **No PC required** - Everything happens in the cloud
✅ **Multiple architectures** - One build, three APKs
✅ **Storage efficient** - Old APKs auto-deleted after 30 days

## 📚 Additional Resources

- **Quick Start Guide**: [README_PLAY_BUILD.md](../README_PLAY_BUILD.md)
- **Complete Build Guide**: [BUILD_PLAY_APK.md](BUILD_PLAY_APK.md)
- **GitHub Actions Documentation**: https://docs.github.com/en/actions
- **Workflow File**: [auto-build-play-apk.yml](../.github/workflows/auto-build-play-apk.yml)

## 👍 Getting Started

**Ready to use automatic builds?**

1. ✅ Set up GitHub Secrets (one time)
2. ✅ Push your code
3. ✅ Wait ~15 minutes
4. ✅ Download and install APK
5. ✅ Repeat whenever you make changes!

---

**Questions?** Check the [troubleshooting section](#-troubleshooting) or open an issue!
