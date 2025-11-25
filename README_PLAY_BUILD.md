# Aves Gallery with OCR - Play Flavor Build

🚀 **Quick-start guide for building the Play flavor APK with OCR features**

## 🤖 NEW: Automatic Builds!

**Your branch now builds APKs automatically on every push!**

✅ Push your code changes  
✅ Wait ~15 minutes  
✅ Download APK from Actions artifacts  
✅ Install on your device  

**See**: [Automatic Build Setup Guide](docs/AUTO_BUILD_SETUP.md)

---

## 🎯 Features

This build includes:

- ✨ **ML Kit OCR** (Google Play Services-based)
- 🔍 **Google Lens-style text overlay** 
- 🌐 **Multi-language support** (Latin, Chinese, Devanagari, Japanese, Korean)
- 📝 **Copy, share, search text**
- 📦 **Optimized APK size** (split-per-abi)

## 🔄 Two Ways to Build

### Option 1: Automatic Build (Recommended)

**Just push your code and get APKs automatically!**

```bash
git add .
git commit -m "Your changes"
git push origin feature/ocr-integration

# APK builds automatically in ~15 minutes!
# Download from Actions tab
```

📚 **Setup Guide**: [Automatic Build Setup](docs/AUTO_BUILD_SETUP.md)

### Option 2: Manual Build

**Trigger builds manually with custom version names**

1. Go to **Actions** tab
2. Select **"Build Play Flavor Release APK"**
3. Click **"Run workflow"**
   - Branch: `feature/ocr-integration`
   - Version: `1.0.0-ocr` (or any name you want)
4. Click **"Run workflow"** button
5. Wait ~10-15 minutes
6. Download APK from Artifacts section

---

## ⚡ Quick Setup (One-Time)

### 🔑 Set Up Secrets

**Required for both automatic and manual builds:**

Add these to your repository secrets (`Settings` → `Secrets and variables` → `Actions`):

```
KEYSTORE_B64       → Base64 of your .jks keystore file
KEYSTORE_PASSWORD  → Your keystore password
KEY_ALIAS          → Your key alias name
KEY_PASSWORD       → Your key password
GOOGLE_API_KEY     → (optional) Your Google API key
```

### 📝 Keystore Quick Setup (Termux)

If you don't have a keystore:

```bash
# Install Java
pkg install openjdk-17

# Generate keystore
keytool -genkey -v -keystore ~/aves.jks -keyalg RSA -keysize 2048 -validity 10000 -alias aves-key

# Convert to base64
base64 ~/aves.jks > ~/aves-b64.txt

# Copy contents to GitHub Secret KEYSTORE_B64
cat ~/aves-b64.txt
```

**Remember your passwords!** You'll need them for the GitHub secrets.

📚 **Detailed Guide**: [Creating a Keystore](docs/BUILD_PLAY_APK.md#2-creating-a-keystore-if-you-dont-have-one)

---

## 📥 Downloading & Installing APKs

### Which APK Should I Download?

| Device Type | APK to Use | Size |
|------------|------------|------|
| 📱 Modern phones (2015+) | **arm64-v8a** ✅ | ~50-60 MB |
| 📡 Older phones (pre-2015) | armeabi-v7a | ~45-55 MB |
| 🖥️ Emulators | x86_64 | ~55-65 MB |

**Not sure?** → Use **arm64-v8a** (works on 95% of devices)

### Download from Actions

1. Go to: https://github.com/osphvdhwj/aves/actions
2. Click on latest completed workflow run (✅ green checkmark)
3. Scroll to **Artifacts** section
4. Download the APK for your device
5. Transfer to phone and install

### APK Naming

**Automatic builds**:
```
aves-play-20251125-1430-a3f2b1c-arm64-v8a.apk
         │        │    │       └─ Architecture
         │        │    └─────── Commit hash
         │        └──────────── Time
         └─────────────────── Date
```

**Manual builds**:
```
aves-play-1.0.0-ocr-arm64-v8a.apk
         │          └─ Architecture  
         └──────────── Your custom version
```

---

## 🔧 Troubleshooting

### Build Issues

**Build fails: "KEYSTORE_B64 not set"**  
➡️ Add the `KEYSTORE_B64` secret in repository settings

**Build fails: "Keystore password incorrect"**  
➡️ Verify `KEYSTORE_PASSWORD` and `KEY_PASSWORD` secrets are correct

**Build takes too long (>20 min)**  
➡️ Normal is 10-15 minutes. Check GitHub Actions status page.

### Installation Issues

**"App not installed" on device**  
➡️ Try **arm64-v8a** APK or uninstall existing Aves first

**"App isn't compatible with your device"**  
➡️ Wrong architecture. Check device specs and try different APK.

### OCR Issues

**OCR button doesn't appear**  
➡️ Only works on images (not videos). Ensure image is fully loaded.

**"Model download failed"**  
➡️ Connect to internet for first OCR use. ML Kit downloads models (~5-8 MB).

**Text not detected**  
➡️ Image quality too low or text too small. Try clearer photo.

📚 **More Help**: [Complete Troubleshooting Guide](docs/BUILD_PLAY_APK.md#-troubleshooting)

---

## 🚀 Using OCR

### Activating OCR

1. Open any image in Aves
2. Tap the **🔍 scan icon** in viewer
3. Wait 1-3 seconds for text recognition
4. Tap text blocks to select them
5. Use **Copy**, **Share**, or **Search** buttons

### First-Time Setup

**Important**: ML Kit downloads language models on first use:
- Latin: ~5 MB
- Chinese: ~8 MB  
- Japanese/Korean: ~6-7 MB each

Models are cached locally after download.

---

## 🆚️ Play vs. Libre Flavor

| Feature | Play Flavor | Libre Flavor |
|---------|------------|-------------|
| **OCR Engine** | ML Kit (Play Services) | Bundled ML Kit |
| **Requires Play Services** | ✅ Yes | ❌ No |
| **APK Size** | 👍 Smaller (50-60 MB) | 📦 Larger (80-100 MB) |
| **Custom ROMs** | ⚠️ Maybe | ✅ Yes |
| **Offline OCR** | ❌ First use needs internet | ✅ Fully offline |
| **F-Droid** | ❌ No | ✅ Yes |

**Choose Play** if you have Google Play Services (most phones).

**Choose Libre** if you use custom ROMs without Play Services.

---

## 📚 Documentation

### Build Guides

- 🤖 **[Automatic Build Setup](docs/AUTO_BUILD_SETUP.md)** - Push and build automatically
- 📝 **[Complete Build Guide](docs/BUILD_PLAY_APK.md)** - Detailed instructions
- ⚙️ **[Manual Build Guide](docs/BUILD_PLAY_APK.md#method-2-local-build-advanced)** - Build locally

### Workflow Files

- **[auto-build-play-apk.yml](.github/workflows/auto-build-play-apk.yml)** - Automatic on push
- **[build-play-release.yml](.github/workflows/build-play-release.yml)** - Manual trigger

### Support

- 🐛 **Issues**: [Open an issue](https://github.com/osphvdhwj/aves/issues) with details
- 💻 **Source**: [feature/ocr-integration branch](https://github.com/osphvdhwj/aves/tree/feature/ocr-integration)
- 📜 **Commits**: [Commit history](https://github.com/osphvdhwj/aves/commits/feature/ocr-integration)

---

## ✨ What's New

Recent updates on this branch:

- 🤖 **Automatic APK builds on push** (NEW!)
- ✅ Google Lens-style selectable text overlay
- ✅ Multi-language OCR (5 language families)
- ✅ GitHub Actions automated builds
- ✅ Split-per-ABI for smaller downloads
- ✅ Proper release signing and obfuscation

See [commit history](https://github.com/osphvdhwj/aves/commits/feature/ocr-integration) for details.

---

## 👍 Quick Start Summary

**For automatic builds (easiest)**:
1. Set up GitHub Secrets (one time)
2. Push your code changes
3. Download APK from Actions after ~15 min
4. Install and use!

**For manual builds**:
1. Set up GitHub Secrets (one time)
2. Go to Actions → Run workflow
3. Download APK from Artifacts
4. Install and use!

---

**Ready?** Set up your secrets and push some code - your APK will build automatically! 🎉

Or head to the [**Actions tab**](https://github.com/osphvdhwj/aves/actions) to trigger a manual build!
